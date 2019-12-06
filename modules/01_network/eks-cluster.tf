#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "nexus-cluster" {
  name = "${format("%s-cluster", var.cluster-name)}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "nexus-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = "${aws_iam_role.nexus-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "nexus-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = "${aws_iam_role.nexus-cluster.name}"
}

resource "aws_security_group" "nexus-cluster" {
  name = "${format("%s-cluster", var.cluster-name)}"
  description = "Cluster communication with worker nodes"
  vpc_id = "${aws_vpc.nexus.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.cluster-name})",
      format("%s%s", "kubernetes.io/cluster/", var.cluster-name), "shared",
      "billing-category", format("%s", "build"),
      "billing-subcategory", format("%s", "nexus")
    )
  )}"
}

resource "aws_security_group_rule" "nexus-cluster-ingress-node-https" {
  description = "Allow pods to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.nexus-cluster.id}"
  source_security_group_id = "${aws_security_group.nexus-node.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_eks_cluster" "nexus" {
  name = "${var.cluster-name}"
  role_arn = "${aws_iam_role.nexus-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.nexus-cluster.id}"]
    subnet_ids = "${aws_subnet.nexus.*.id}"
  }

  depends_on = [
    "aws_iam_role_policy_attachment.nexus-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.nexus-cluster-AmazonEKSServicePolicy",
  ]
}
