PACKAGE_NAME?=

all:
	mkdir package
	pip3 install \
	--platform manylinux2014_x86_64 \
	--target=package \
	--implementation cp \
	--only-binary=:all: --upgrade \
	-r requirements.txt
	cp main.py ./package/main.py
	cd package && zip -r ../$(PACKAGE_NAME).zip .
	rm -rf package
