##############################
# Definitions
##############################

REQUIRED_BINS = svn wget java python

##############################
# Rules
##############################

all: deps games

index: common
	python build/compress.py index

puzzle: common
	python build/compress.py puzzle

maze: common
	python build/compress.py maze

bird: common
	python build/compress.py bird

turtle: common
	python build/compress.py turtle

movie: common
	python build/compress.py movie

music: common
	python build/compress.py music

pond-tutor: common
	python build/compress.py pond/tutor

pond-duck: common
	python build/compress.py pond/duck

gallery: common
	python build/compress.py gallery

games: index puzzle maze bird turtle movie music pond-tutor pond-duck gallery

common:
	@echo "Converting messages.js to JSON for Translatewiki."
	python build/messages_to_json.py
	@echo "Converting JSON from Translatewiki to message files."
	python build/json_to_js.py
	@echo

deps:
	$(foreach bin,$(REQUIRED_BINS),\
	    $(if $(shell command -v $(bin) 2> /dev/null),$(info Found `$(bin)`),$(error Please install `$(bin)`)))
	mkdir -p build/third-party-downloads
	wget -N https://unpkg.com/google-closure-compiler-java/compiler.jar;
	mv -f compiler.jar build/third-party-downloads/closure-compiler.jar;

	mkdir -p appengine/third-party
	wget -N https://unpkg.com/@babel/standalone@7.14.8/babel.min.js
	mv babel.min.js appengine/third-party/
	@# GitHub doesn't support git archive, so download files using svn.
	git clone -n --depth=1 --filter=tree:0 https://github.com/ajaxorg/ace-builds \
	&& cd ace-builds \
    && git sparse-checkout set --no-cone src-min-noconflict \
    && git checkout

	mkdir -p appengine/third-party/blockly
	git clone git@github.com:NeilFraser/blockly-for-BG.git appengine/third-party/blockly

	git clone -n --depth=1 --filter=tree:0 git@github.com:CreateJS/SoundJS.git \
    && cd SoundJS \
    && git sparse-checkout set --no-cone lib \
    && git checkout

	cp third-party/base.js appengine/third-party/
	cp -R third-party/soundfonts appengine/third-party/

	git clone git@github.com:NeilFraser/JS-Interpreter.git appengine/third-party/JS-Interpreter
	@# Compile JS-Interpreter using SIMPLE_OPTIMIZATIONS because the Music game needs to mess with the stack.
	java -jar build/third-party-downloads/closure-compiler.jar\
	  --language_out ECMASCRIPT5\
	  --language_in ECMASCRIPT5\
	  --js appengine/third-party/JS-Interpreter/acorn.js\
	  --js appengine/third-party/JS-Interpreter/interpreter.js\
	  --js_output_file appengine/third-party/JS-Interpreter/compressed.js

offline: clean-offline
	mkdir offline
	cp -R appengine offline/blockly-games
	rm -f offline/blockly-games/*.{yaml,py,sh}
	rm -f offline/blockly-games/{admin.html,apple-touch-icon.png,favicon.ico,robots.txt}
	rm -rf offline/blockly-games/gallery*
	rm -rf offline/blockly-games/generated/
	rm -rf offline/blockly-games/{./,*,*/*}/src
	rm -f offline/blockly-games/{./,*,*/*}/generated/uncompressed.js
	rm -f offline/blockly-games/index/title.png
	rm -f offline/blockly-games/index/title-beta.png
	rm -f offline/blockly-games/pond/crobots.txt
	rm -rf offline/blockly-games/pond/battle
	rm -f offline/blockly-games/common/stripes.svg
	rm -f offline/blockly-games/third-party/base.js
	rm -f offline/blockly-games/third-party/soundfonts/README.txt

	mv offline/blockly-games/third-party/ace/{ace.js,mode-javascript.js,theme-chrome.js,worker-javascript.js} offline/
	rm -rf offline/blockly-games/third-party/ace/*
	mv offline/{ace.js,mode-javascript.js,theme-chrome.js,worker-javascript.js} offline/blockly-games/third-party/ace/

	mv offline/blockly-games/third-party/SoundJS/soundjs.min.js offline/
	rm -rf offline/blockly-games/third-party/SoundJS/*
	mv offline/soundjs.min.js offline/blockly-games/third-party/SoundJS/

	mv offline/blockly-games/third-party/blockly/media/ offline/
	rm -rf offline/blockly-games/third-party/blockly/*
	mv offline/media/ offline/blockly-games/third-party/blockly/

	mv offline/blockly-games/third-party/JS-Interpreter/compressed.js offline/
	rm -rf offline/blockly-games/third-party/JS-Interpreter/{*,.gitignore}
	mv offline/compressed.js offline/blockly-games/third-party/JS-Interpreter/

	echo '<html><head><meta http-equiv=refresh content="0; url=blockly-games/index.html"/></head></html>' > offline/blockly-games.html
	find offline -name '.DS_Store' -delete

	cd offline; \
	zip -r9 blockly-games.zip blockly-games/ blockly-games.html

clean: clean-games clean-offline clean-deps

clean-games:
	rm -rf appengine/{.,index,puzzle,maze,bird,turtle,movie,music,pond,pond/tutor,pond/duck,gallery}/generated

clean-offline:
	rm -rf offline/

clean-deps:
	rm -rf appengine/third-party
	rm -rf build/third-party-downloads
	rm -rf ace-builds
	rm -rf SoundJS

# Prevent non-traditional rules from exiting with no changes.
.PHONY: deps
