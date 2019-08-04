.PHONY = all build

all: build

build:
	docker build -t sckyzo/nextcloud:16.0.3 -t sckyzo/nextcloud:latest 16.0.3 

publish:
	docker push sckyzo/nextcloud
