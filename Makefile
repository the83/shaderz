run:
	npm start

deploy:
	scp shaders/*.glsl pi@raspberrypi.local:PATTERN/
