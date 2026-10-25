module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  environment          = "Learning"
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = aws_security_group.alb.id
  alarm_actions     = var.alarm_actions
}

module "asg" {
  source = "./modules/asg"

  subnet_ids        = module.vpc.public_subnet_ids
  target_group_arn  = module.alb.target_group_arn
  security_group_id = aws_security_group.app.id
}
