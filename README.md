# Secure self-custody of blockchain assets

I explain the idea in the text file.
Here is a quick made implementation in solidity. It is still in progress so **do not use as it is**.

To run the test suite, install truffle through npm, install ganache from their website then run 'truffle test' at root.


# TL;DR
- You receive 2 cryptographic (pair of) keys to manage funds through a smart-contract.
- A service provider keeps one of them.
- The authority of spending funds is linked to the other key. If you loose it or if it was stolen, the service provider can provide you another key to spend the funds and block the previous one.
- To protect yourself from malicious service provider, you can prevent any action of the provider if you have both keys.

Note that the service provider can be just a simple cloud storage service where you would save your private key without risking compromising your funds. You will then register the smart-contract and manage it yourself. In the text file I am thinking of a more engaged service provider who could provide self-custody for people who are not comfortable with advanced technology.