# This Makefile is meant to be used by people that do not usually work
# with Go source code. If you know what GOPATH is then you probably
# don't need to bother with make.

.PHONY: gem android ios gem-cross swarm evm all test clean
.PHONY: gem-linux gem-linux-386 gem-linux-amd64 gem-linux-mips64 gem-linux-mips64le
.PHONY: gem-linux-arm gem-linux-arm-5 gem-linux-arm-6 gem-linux-arm-7 gem-linux-arm64
.PHONY: gem-darwin gem-darwin-386 gem-darwin-amd64
.PHONY: gem-windows gem-windows-386 gem-windows-amd64

GOBIN = $(shell pwd)/build/bin
GO ?= latest

gem:
	build/env.sh go run build/ci.go install ./cmd/gem
	@echo "Done building."
	@echo "Run \"$(GOBIN)/gem\" to launch gem."

swarm:
	build/env.sh go run build/ci.go install ./cmd/swarm
	@echo "Done building."
	@echo "Run \"$(GOBIN)/swarm\" to launch swarm."

all:
	build/env.sh go run build/ci.go install

android:
	build/env.sh go run build/ci.go aar --local
	@echo "Done building."
	@echo "Import \"$(GOBIN)/gem.aar\" to use the library."

ios:
	build/env.sh go run build/ci.go xcode --local
	@echo "Done building."
	@echo "Import \"$(GOBIN)/Geth.framework\" to use the library."

test: all
	build/env.sh go run build/ci.go test

lint: ## Run linters.
	build/env.sh go run build/ci.go lint

clean:
	./build/clean_go_build_cache.sh
	rm -fr build/_workspace/pkg/ $(GOBIN)/*

# The devtools target installs tools required for 'go generate'.
# You need to put $GOBIN (or $GOPATH/bin) in your PATH to use 'go generate'.

devtools:
	env GOBIN= go get -u golang.org/x/tools/cmd/stringer
	env GOBIN= go get -u github.com/kevinburke/go-bindata/go-bindata
	env GOBIN= go get -u github.com/fjl/gencodec
	env GOBIN= go get -u github.com/golang/protobuf/protoc-gen-go
	env GOBIN= go install ./cmd/abigen
	@type "npm" 2> /dev/null || echo 'Please install node.js and npm'
	@type "solc" 2> /dev/null || echo 'Please install solc'
	@type "protoc" 2> /dev/null || echo 'Please install protoc'

# Cross Compilation Targets (xgo)

gem-cross: gem-linux gem-darwin gem-windows gem-android gem-ios
	@echo "Full cross compilation done:"
	@ls -ld $(GOBIN)/gem-*

gem-linux: gem-linux-386 gem-linux-amd64 gem-linux-arm gem-linux-mips64 gem-linux-mips64le
	@echo "Linux cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-*

gem-linux-386:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/386 -v ./cmd/gem
	@echo "Linux 386 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep 386

gem-linux-amd64:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/amd64 -v ./cmd/gem
	@echo "Linux amd64 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep amd64

gem-linux-arm: gem-linux-arm-5 gem-linux-arm-6 gem-linux-arm-7 gem-linux-arm64
	@echo "Linux ARM cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep arm

gem-linux-arm-5:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/arm-5 -v ./cmd/gem
	@echo "Linux ARMv5 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep arm-5

gem-linux-arm-6:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/arm-6 -v ./cmd/gem
	@echo "Linux ARMv6 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep arm-6

gem-linux-arm-7:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/arm-7 -v ./cmd/gem
	@echo "Linux ARMv7 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep arm-7

gem-linux-arm64:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/arm64 -v ./cmd/gem
	@echo "Linux ARM64 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep arm64

gem-linux-mips:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/mips --ldflags '-extldflags "-static"' -v ./cmd/gem
	@echo "Linux MIPS cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep mips

gem-linux-mipsle:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/mipsle --ldflags '-extldflags "-static"' -v ./cmd/gem
	@echo "Linux MIPSle cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep mipsle

gem-linux-mips64:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/mips64 --ldflags '-extldflags "-static"' -v ./cmd/gem
	@echo "Linux MIPS64 cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep mips64

gem-linux-mips64le:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=linux/mips64le --ldflags '-extldflags "-static"' -v ./cmd/gem
	@echo "Linux MIPS64le cross compilation done:"
	@ls -ld $(GOBIN)/gem-linux-* | grep mips64le

gem-darwin: gem-darwin-386 gem-darwin-amd64
	@echo "Darwin cross compilation done:"
	@ls -ld $(GOBIN)/gem-darwin-*

gem-darwin-386:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=darwin/386 -v ./cmd/gem
	@echo "Darwin 386 cross compilation done:"
	@ls -ld $(GOBIN)/gem-darwin-* | grep 386

gem-darwin-amd64:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=darwin/amd64 -v ./cmd/gem
	@echo "Darwin amd64 cross compilation done:"
	@ls -ld $(GOBIN)/gem-darwin-* | grep amd64

gem-windows: gem-windows-386 gem-windows-amd64
	@echo "Windows cross compilation done:"
	@ls -ld $(GOBIN)/gem-windows-*

gem-windows-386:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=windows/386 -v ./cmd/gem
	@echo "Windows 386 cross compilation done:"
	@ls -ld $(GOBIN)/gem-windows-* | grep 386

gem-windows-amd64:
	build/env.sh go run build/ci.go xgo -- --go=$(GO) --targets=windows/amd64 -v ./cmd/gem
	@echo "Windows amd64 cross compilation done:"
	@ls -ld $(GOBIN)/gem-windows-* | grep amd64
