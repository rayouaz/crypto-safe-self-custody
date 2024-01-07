# Safe self custody
A contract-based solution for secure self-custody of blockchain assets

I present the solution in the paper
I added a quick made implemention in solidity, in progress and not even teste so DO NOT USE AS IT IS.
TLDR: 
- You receive both keys to manage fnunds through a smart-contract.
- A service provider keeps one of them.
- The authority of spending fund is linked to the other key. If you loose it or if it was stolen, the service provider can provide you another key to spend the funds.
- To protect yourself from malicious service provider, you can prevent any action of the provider if you have both keys.
