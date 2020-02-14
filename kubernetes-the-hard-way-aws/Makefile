kill:
	@./clean.sh
	@rm -f key*
	@rm -fr cert/
	@rm $(HOME)/.kube/config

deploy:
	@./setup.sh
	@./cert.sh
	@./config.sh
	@./encrypt.sh
	@./etcd.sh
	@./controller_plane.sh
	@./worker.sh
	@./remote.sh
	@./11-pod-network-routes.sh

.PHONY: kill deploy
