### What this contract does
- A Governance Contract that gives the user the right to vote on a platfrom proposal
- users can have selef-delegation or they can delegate to other users to vote on their side.
### Why ERC20Votes instead of ERC20
- A flash loan attack in governance happens when an attacker temporarily borrows a huge amount of tokens, gains voting power, and manipulates a proposal before repaying the loan in the same transaction or shortly after.
- Snapshots solve this by recording voting power at a specific historical block, so governance decisions use past balances instead of current balances.
- This prevents attackers from gaining instant voting power through temporary token ownership.
### How to run the tests 
- Build the Dependancies `forge build`
- Run All Tests `forge test`
- Display a report of which lines got excuted`forge coverage`