

resource "aws_ecs_task_definition" "task2" {
  family                   = "task2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${data.aws_iam_role.ecs-task.arn}"

  container_definitions = jsonencode([
    {
      name   = "service3"
      image  = "${aws_ecrpublic_repository.ecr3.repository_uri}" 
      cpu    = 256
      memory = 512
      portMappings = [
        {
          containerPort = 80

        }
      ]
    }
  ])
}




resource "aws_ecs_service" "svc3" {
  name            = "service3"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.task2.id}"
  desired_count   = 2
  launch_type     = "FARGATE"


  network_configuration {
    subnets          = ["${aws_subnet.pub-a.id}", "${aws_subnet.pub-b.id}"]
    security_groups  = ["${aws_security_group.sg3.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg2-group.arn}"
    container_name   = "service3"
    container_port   = "80"
  }
}


resource "aws_codebuild_project" "dr_docker2_build2" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "dr_docker2_build2"
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild_role.arn
  tags = {
    Environment = var.env
  }

  artifacts {
    
    type                   = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/gpswarwal/dockerfile.git"
    git_clone_depth = 1
  }
}



resource "aws_codepipeline" "dr_pipeline2" {
  name     = "dr_pipeline2"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"
  }
  # SOURCE
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      input_artifacts  = []
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "gpswarwal"
        Repo       = "dockerfile"
        Branch     = "main"
        OAuthToken = "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"
      }
    }
  }
  # BUILD
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "dr_docker2_build2"
      }
    }
  }
  # DEPLOY
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = "clusterDev"
        ServiceName = "react3-Service"
        FileName    = "service3.json"
      }
    }
  }
}


resource "aws_appautoscaling_target" "ecs_target2" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/clusterDev/service3"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_appautoscaling_policy" "scale_up_policy2" {
  name               = "scale_up_policy2"
  depends_on         = [aws_appautoscaling_target.ecs_target2]
  service_namespace  = "ecs"
  resource_id        = "service/clusterDev/service3"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}





resource "aws_appautoscaling_policy" "scale_down_policy2" {
  name               = "scale_down_policy2"
  depends_on         = [aws_appautoscaling_target.ecs_target2]
  service_namespace  = "ecs"
  resource_id        = "service/clusterDev/service3"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "cpu_high2" {
  alarm_name          = "cpu-high2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3                              #"The number of periods over which data is compared to the specified threshold for max cpu metric alarm"
  metric_name         = "CPUUtilization2"
  namespace           = "AWS/ECS"
  period              = 60                              #"The number of periods over which data is compared to the specified threshold for min cpu metric alarm"
  statistic           = "Maximum"
  threshold           = 80
  
  alarm_actions = [aws_appautoscaling_policy.scale_up_policy2.arn]

  
}


resource "aws_cloudwatch_metric_alarm" "cpu_low2" {
  alarm_name          = "cpu-low2"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization2"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 10
  
  alarm_actions = [aws_appautoscaling_policy.scale_down_policy2.arn]

  
}
