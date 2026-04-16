run:
	npm start

build:
	@rm -rf build && mkdir build
	@for f in shaders/*.glsl; do \
		cp "$$f" build/$$(basename "$$f" .glsl).frag; \
	done

deploy: build
	scp build/*.frag pi@raspberrypi.local:PATTERN/
