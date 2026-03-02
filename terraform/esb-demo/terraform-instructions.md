# Created Resources
esb_build_instance_id = "i-0817d428b702bdf02"                                                                                                                                           
esb_deploy_instance_id = "i-0b3bfea7e65d4f86a"
esb_ssm_role_arn = "arn:aws:iam::289491622160:role/esb-ssm-role"

# Log into ESB Build instance via ssm
```bash
aws ssm start-session --target "i-0817d428b702bdf02"
cd /home/ssm-user/
```

# Copy file using aws cp
```bash
# copy from esb-build to s3
aws s3 cp /home/ssm-user/scratch/target/rest-service-complete-0.0.1-SNAPSHOT.jar s3://esb-to-ace-transfer

# copy from s3 to esb-deploy
aws s3 cp s3://esb-to-ace-transfer/rest-service-complete-0.0.1-SNAPSHOT.jar /home/ssm

```
