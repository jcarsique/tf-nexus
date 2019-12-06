### Nexus Docker "docker-registry" (public)

resource "aws_alb" "docker_registry" {
  name                       = "nexus-${var.environment}-docker-registry"
  internal                   = false
  security_groups            = [
    "${aws_security_group.nexus-alb.id}"]
  subnets                    = "${aws_subnet.nexus.*.id}"
  enable_deletion_protection = false
  idle_timeout               = 300

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.cluster-name}",
      format("%s%s", "kubernetes.io/cluster/", var.cluster-name), "shared",
      "billing-category", format("%s", "build"),
      "billing-subcategory", format("%s", "nexus"),
      "environment", format("%s", var.environment)
    )
  )}"
}

resource "aws_lb_listener" "alb_docker_registry" {
  load_balancer_arn = "${aws_alb.docker_registry.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.aws_lb_listener_certificate_arn}"
  default_action {
    target_group_arn = "${aws_alb_target_group.docker_registry.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "redirect_docker_registry" {
  load_balancer_arn = "${aws_alb.docker_registry.arn}"
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

resource "aws_alb_target_group" "docker_registry" {
  name        = "nexus-${var.environment}-docker-registry"
  vpc_id      = "${aws_vpc.nexus.id}"
  port        = "32021"
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

resource "aws_autoscaling_attachment" "docker_registry" {
  alb_target_group_arn   = "${aws_alb_target_group.docker_registry.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.nexus.id}"
}
