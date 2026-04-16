run:
	npm start

build:
	@rm -rf build && mkdir build
	@for f in shaders/*.glsl; do \
		name=$$(basename "$$f" .glsl).frag; \
		cat recurboy_header.glsl > build/"$$name"; \
		grep -v '^\s*uniform\s\+\(float\s\+u_\|vec2\s\+u_\)' "$$f" >> build/"$$name"; \
	done

deploy: build
	scp build/*.frag pi@raspberrypi.local:PATTERN/
