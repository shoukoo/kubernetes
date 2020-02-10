kill:
	@./clean.sh
	@rm -f key*
	@rm -fr cert/

deploy:
	@./setup.sh
	@./cert.sh
	@./config.sh
	@./encrypt.sh
	@./etcd.sh
	@./controller_plane.sh
	@./worker.sh

.PHONY: kill deploy
