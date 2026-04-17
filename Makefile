.PHONY: run build deploy

run:
	npm start

build:
	@rm -rf build && mkdir build
	@for f in shaders/recurboy/*.glsl; do \
		name=$$(basename "$$f" .glsl).frag; \
		cat recurboy_header.glsl > build/"$$name"; \
		grep -v '^\s*uniform\s\+\(float\s\+u_\|vec2\s\+u_\)' "$$f" >> build/"$$name"; \
	done

deploy: build
	ssh pi@raspberrypi.local 'rm -f PATTERN/*.frag'
	scp build/*.frag pi@raspberrypi.local:PATTERN/
	ssh pi@raspberrypi.local 'sync'
