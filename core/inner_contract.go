package core

import (
	"github.com/gem/go-gem/accounts/abi"
	"github.com/gem/go-gem/common"
	"github.com/gem/go-gem/core/state"
	"github.com/gem/go-gem/core/types"
	"github.com/gem/go-gem/core/vm"
	"github.com/gem/go-gem/log"
	"github.com/gem/go-gem/params"
	"math"
	"math/big"
	"strings"
)

// ABI definition of built-in contract.
var innerABIDefinition = `[{"constant":false,"inputs":[{"name":"_coinbase","type":"address"}],"name":"updateCoinbase","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":false,"inputs":[{"name":"_nodeId","type":"string"}],"name":"addNodeId","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"whiteList","outputs":[{"name":"nodeId","type":"string"},{"name":"state","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"_nodeId","type":"string"}],"name":"removeNodeId","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[{"name":"nodeId","type":"string"}],"name":"isWhite","outputs":[{"name":"_exists","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[],"name":"getCoinbase","outputs":[{"name":"_coinbase","type":"address"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"inputs":[],"payable":false,"type":"constructor","stateMutability":"nonpayable"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":false,"name":"errno","type":"uint256"},{"indexed":true,"name":"errmsg","type":"string"}],"name":"Response","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_prevOwner","type":"address"},{"indexed":false,"name":"_newOwner","type":"address"}],"name":"OwnerUpdate","type":"event"}]`

// address of build-in contract.
var innerContractAddress = common.HexToAddress("0x1000000000000000000000000000000000000001");

const (
	defaultGasLimit = math.MaxUint64 / 2
	defaultGasPrice = params.GWei

	InnerExtraSeal = 64
)

type InnerContract struct {
	header *types.Header
	blockChain *BlockChain
	state *state.StateDB
	chainConfig *params.ChainConfig
}

func NewInnerContract(header *types.Header, bc *BlockChain, state *state.StateDB, config *params.ChainConfig) *InnerContract {
	return &InnerContract{
		header: header,
		blockChain: bc,
		state: state,
		chainConfig: config,
	}
}

func (inner *InnerContract) evm() *vm.EVM {
	msg := types.NewMessage(inner.header.Coinbase, &innerContractAddress, 0, big.NewInt(0),
		defaultGasLimit , big.NewInt(defaultGasPrice), []byte{}, false)
	context := NewEVMContext(msg, inner.header, inner.blockChain, nil)
	evm := vm.NewEVM(context, inner.state, inner.chainConfig, vm.Config{})
	return evm
}

// Returns the package permission of the specified NodeID.
func (inner *InnerContract) IsValid(publicKeyStr string) (bool, int64) {
	evm := inner.evm()
	abi, err := abi.JSON(strings.NewReader(innerABIDefinition))
	if err != nil {
		log.Error("Parse abi fail", "err", err)
	}

	// Call the contract's isWhite method to determine if it is valid.
	input, _ := abi.Pack("isWhite", publicKeyStr)
	ret, _, err := evm.Call(vm.AccountRef(inner.header.Coinbase), innerContractAddress, input, defaultGasLimit, big.NewInt(0))
	log.Info("Call inner contract", "ret", common.Bytes2Hex(ret), "err", err)

	// Decoding result returned by the contract.
	var isWhite *big.Int
	err = abi.Unpack(&isWhite, "isWhite", ret)
	if err != nil {
		log.Error("Unpack from abi fail", "err", err)
	}
	// 1 indicates that there is permission to package.
	white := isWhite.Int64()
	return white == 1 || white == 2, white
}

// Returns the address specified to receive the reward.
func (inner *InnerContract) Coinbase() common.Address {
	abi, err := abi.JSON(strings.NewReader(innerABIDefinition))
	if err != nil {
		log.Error("Parse abi fail in the Coinbase", "err", err)
	}

	// pack params.
	input, _ := abi.Pack("getCoinbase")
	log.Info("Call getCoinbase of inner contract", "input", common.Bytes2Hex(input))

	// call contract.
	evm := inner.evm()
	ret, _, err := evm.Call(vm.AccountRef(inner.header.Coinbase), innerContractAddress, input, defaultGasLimit, big.NewInt(0))
	log.Info("Response for getCoinase", "coinbase", common.Bytes2Hex(ret))

	// uppack response.
	var coinbase common.Address
	err = abi.Unpack(&coinbase, "getCoinbase", ret)
	return coinbase
}

