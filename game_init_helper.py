from Crypto import Random
from web3 import Web3

nonce = Random.get_random_bytes(32)
choice = int(input("Rock - 1 | Paper - 2 | Scissors - 3\n"))
assert (choice == 1 | choice == 2 | choice == 3, "Bad input")
print(f"nonce: 0x{nonce.hex()}")
web3keccak = Web3.solidityKeccak(['uint8', 'bytes32'], [choice, nonce])
print(f"commitment: {web3keccak.hex()}")
