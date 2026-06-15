.PHONY: terraform deploy update-image destroy

terraform:
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve

deploy:
	chmod +x build_and_deploy.sh
	./build_and_deploy.sh

update-image:
	chmod +x build_and_deploy.sh
	./build_and_deploy.sh

destroy:
	cd terraform && terraform destroy -auto-approve