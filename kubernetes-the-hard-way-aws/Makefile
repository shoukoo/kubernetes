kill:
	@./clean.sh
	@rm -f key*
	@rm -fr cert/
	@rm $(HOME)/.kube/config

deploy:
	@./03-compute-resources.sh
	@./04-certificate-authority.sh
	@./05-kubernetes-configuration-files.sh
	@./06-data-encryption-keys.sh
	@./07-bootstrapping-etcd.sh
	@./08-bootstrapping-kubernetes-controllers.sh
	@./09-bootstrapping-kubernetes-workers.sh
	@./10-configuring-kubectl.sh
	@./11-pod-network-routes.sh
	@./12-dns-addon.sh
	@./13-smoke-test.sh

.PHONY: kill deploy
