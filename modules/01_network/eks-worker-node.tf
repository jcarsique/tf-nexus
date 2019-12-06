#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

resource "aws_iam_role" "nexus-node" {
}

resource "aws_iam_role_policy_attachment" "nexus-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.nexus-node.name}"
}

resource "aws_iam_role_policy_attachment" "nexus-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.nexus-node.name}"
}

resource "aws_iam_role_policy_attachment" "nexus-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.nexus-node.name}"
}

resource "aws_iam_role_policy_attachment" "nexus-node-AmazonEC2S3BlobstoreAccess" {
  policy_arn = "arn:aws:iam::762822024843:policy/terraform-nexus-central"
  role       = "${aws_iam_role.nexus-node.name}"
}

resource "aws_iam_policy" "hazelcastDiscovery" {
  name = "hazelcastDiscovery"
}

resource "aws_iam_role_policy_attachment" "nexus-node-hazelcastDiscovery" {
  policy_arn = "${aws_iam_policy.hazelcastDiscovery.arn}"
  role = "${aws_iam_role.nexus-node.name}"
}

resource "aws_iam_instance_profile" "nexus-node" {
  name = "${var.cluster-name}"
  role = "${aws_iam_role.nexus-node.name}"
}

resource "aws_security_group" "nexus-node" {
  name        = "${format("%s-node", var.cluster-name)}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.nexus.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.cluster-name}",
      format("%s%s", "kubernetes.io/cluster/", var.cluster-name), "shared",
      "billing-category", format("%s", "build"),
      "billing-subcategory", format("%s", "nexus")
    )
  )}"
}

resource "aws_security_group_rule" "nexus-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.nexus-node.id}"
  source_security_group_id = "${aws_security_group.nexus-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}


resource "aws_security_group_rule" "nexus-node-ingress-alb" {
  description              = "Allow ALB to nodes"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.nexus-node.id}"
  source_security_group_id = "${aws_security_group.nexus-alb.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nexus-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.nexus-node.id}"
  source_security_group_id = "${aws_security_group.nexus-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = [
      "amazon-eks-node-${aws_eks_cluster.nexus.version}-v*"]
  }

  most_recent = true
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  nexus-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.nexus.endpoint}' --b64-cluster-ca '${aws_eks_cluster.nexus.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "nexus" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.nexus-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "${var.ec2_instance_type}"
  name_prefix                 = "${var.cluster-name}"
  key_name                    = "nexus"
  security_groups             = [
    "${aws_security_group.nexus-node.id}"]
  user_data_base64            = "${base64encode(local.nexus-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nexus" {
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.nexus.id}"
  max_size             = 3
  min_size             = 1
  name                 = "${var.cluster-name}"
  vpc_zone_identifier  = "${aws_subnet.nexus.*.id}"
  target_group_arns    = [
    "${aws_alb_target_group.alb_front_https.arn}",
    "${aws_alb_target_group.docker_private.arn}",
    "${aws_alb_target_group.docker_registry.arn}",
    "${aws_alb_target_group.docker_arender.arn}",
    "${aws_alb_target_group.nexus_iq.arn}",
    "${aws_alb_target_group.nexus_iq_admin.arn}"
  ]
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "billing-category"
    value               = "build"
    propagate_at_launch = true
  }
  tag {
    key                 = "billing-subcategory"
    value               = "nexus"
    propagate_at_launch = true
  }
}

### Nexus ALB

resource "aws_alb" "alb_front" {
  name                       = "${var.cluster-name}"
  internal                   = false
  security_groups            = [
    "${aws_security_group.nexus-alb.id}"]
  subnets                    = "${aws_subnet.nexus.*.id}"
  enable_deletion_protection = false

}


resource "aws_alb_target_group" "alb_front_https" {
  name        = "nexus-${var.environment}-https"
  vpc_id      = "${aws_vpc.nexus.id}"
  port        = "32000"
  protocol    = "HTTP"
  target_type = "instance"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true

  }
  health_check {
    path                = "/service/rest/v1/status"
    port                = "32000"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 10
    interval            = 10
    timeout             = 5
  }
}

resource "aws_alb_listener" "alb_front_https" {
  load_balancer_arn = "${aws_alb.alb_front.arn}"
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    target_group_arn = "${aws_alb_target_group.alb_front_https.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "alb_front_http" {
  load_balancer_arn = "${aws_alb.alb_front.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_autoscaling_attachment" "svc_https" {
  alb_target_group_arn   = "${aws_alb_target_group.alb_front_https.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.nexus.id}"
}

resource "aws_security_group" "nexus-alb" {
  name        = "${format("%s-alb", var.cluster-name)}"
  description = "Security group for ingress ALB"
  vpc_id      = "${aws_vpc.nexus.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = "${merge(
    var.default_tags,
    map(
        "Name", "${var.cluster-name}",
        format("%s%s", "kubernetes.io/cluster/", var.cluster-name), "shared",
        "billing-category", format("%s", "build"),
        "billing-subcategory", format("%s", "nexus")
    )
  )}"
}

resource "aws_security_group_rule" "nexus-alb-http" {
  description       = "Nexus ALB HTTP"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.nexus-alb.id}"
  cidr_blocks       = [
    "0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group_rule" "nexus-alb-https" {
  description       = "Nexus ALB HTTPS"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.nexus-alb.id}"
  cidr_blocks       = [
    "0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_route53_record" "nexus_central" {
  zone_id = "Z3864RCURWFE3D"
  name    = "${var.route53_dns_name.nexus-central}"
  type    = "A"

  alias {
    name                   = "${aws_alb.alb_front.dns_name}"
    zone_id                = "${aws_alb.alb_front.zone_id}"
    evaluate_target_health = true
  }
}
