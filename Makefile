run:
	@make -C user build
	@make -C os run

clean:
	@make -C user clean
	@make -C os clean