import { ProposalCreated, VoteCast } from "../../generated/GameGovernor/GameGovernor";
import { Proposal, Vote } from "../../generated/schema";

export function handleProposalCreated(event: ProposalCreated): void {
  let proposal = new Proposal(event.params.proposalId.toString());
  proposal.proposer = event.params.proposer;
  proposal.description = event.params.description;
  proposal.state = "Pending";
  proposal.createdAt = event.block.timestamp;
  proposal.save();
}

export function handleVoteCast(event: VoteCast): void {
  let vote = new Vote(
    event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
  );
  vote.proposal = event.params.proposalId.toString();
  vote.voter = event.params.voter;
  vote.support = event.params.support;
  vote.weight = event.params.weight;
  vote.reason = event.params.reason;
  vote.save();
}
