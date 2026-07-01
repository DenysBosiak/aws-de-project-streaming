ENV ?= dev
REGION ?= eu-north-1
TF = cd terraform && terraform
ACCOUNT := $(shell aws sts get-caller-identity --query Account --output text)

.PHONY: init plan up-storage up-compute down-compute destroy seed test

init:
	$(TF) init -reconfigure -backend-config="bucket=tfstate-p1-$(ACCOUNT)" -backend-config="key=p1-streaming/terraform.tfstate" -backend-config="region=$(REGION)"

up-storage:
	$(TF) apply -target=module.storage -target=module.iam -var-file="envs/$(ENV).tfvars" -auto-approve

up-compute:
	$(TF) apply -target=module.compute -target=module.analytics -var-file="envs/$(ENV).tfvars" -auto-approve

down-compute:
	$(TF) destroy -target=module.analytics -target=module.compute -var-file="envs/$(ENV).tfvars" -auto-approve

destroy:
	@powershell -Command \
	"$$c = Read-Host 'DELETE ALL DATA? Type YES: '; \
	if ($$c -ne 'YES') { exit 1 }"
	$(TF) destroy -var-file="envs/$(ENV).tfvars" -auto-approve

seed:
	python scripts/replay_kaggle_events.py --file data/raw/2019-Oct.csv --stream ecommerce-events-$(ENV) --limit 1000