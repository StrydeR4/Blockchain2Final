import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  http,
  createConfig,
  useAccount,
  useConnect,
  useReadContract,
  useWriteContract,
  WagmiProvider
} from "wagmi";
import { baseSepolia } from "wagmi/chains";
import { injected, walletConnect } from "wagmi/connectors";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { request, gql } from "graphql-request";
import "./styles.css";

const queryClient = new QueryClient();

const config = createConfig({
  chains: [baseSepolia],
  connectors: [
    injected(),
    walletConnect({ projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID ?? "demo" })
  ],
  transports: {
    [baseSepolia.id]: http(import.meta.env.VITE_BASE_SEPOLIA_RPC_URL)
  }
});

const erc20Abi = [
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "delegates",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ type: "address" }]
  },
  {
    type: "function",
    name: "getVotes",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "delegate",
    stateMutability: "nonpayable",
    inputs: [{ name: "delegatee", type: "address" }],
    outputs: []
  }
] as const;

const ammAbi = [
  {
    type: "function",
    name: "reserves",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }, { type: "uint256" }]
  },
  {
    type: "function",
    name: "swap",
    stateMutability: "nonpayable",
    inputs: [
      { name: "tokenIn", type: "address" },
      { name: "amountIn", type: "uint256" },
      { name: "minAmountOut", type: "uint256" }
    ],
    outputs: [{ type: "uint256" }]
  }
] as const;

const governorAbi = [
  {
    type: "function",
    name: "castVote",
    stateMutability: "nonpayable",
    inputs: [
      { name: "proposalId", type: "uint256" },
      { name: "support", type: "uint8" }
    ],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "state",
    stateMutability: "view",
    inputs: [{ name: "proposalId", type: "uint256" }],
    outputs: [{ type: "uint8" }]
  }
] as const;

const addresses = {
  govToken: (import.meta.env.VITE_GOV_TOKEN ??
    "0x0000000000000000000000000000000000000000") as `0x${string}`,
  amm: (import.meta.env.VITE_AMM ?? "0x0000000000000000000000000000000000000000") as `0x${string}`,
  wood: (import.meta.env.VITE_WOOD ??
    "0x0000000000000000000000000000000000000000") as `0x${string}`,
  governor: (import.meta.env.VITE_GOVERNOR ??
    "0x0000000000000000000000000000000000000000") as `0x${string}`,
  subgraph: import.meta.env.VITE_SUBGRAPH_URL ?? ""
};

function formatWei(value?: bigint) {
  if (value === undefined) return "-";
  return Number(value / 10n ** 16n) / 100;
}

function Dashboard() {
  const { address, chain } = useAccount();
  const { connectors, connect, error: connectError } = useConnect();
  const { writeContractAsync, error: writeError, isPending } = useWriteContract();
  const [uiError, setUiError] = useState("");

  const wrongNetwork = chain && chain.id !== baseSepolia.id;
  const enabled = Boolean(address);
  const balance = useReadContract({
    address: addresses.govToken,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled }
  });
  const votes = useReadContract({
    address: addresses.govToken,
    abi: erc20Abi,
    functionName: "getVotes",
    args: address ? [address] : undefined,
    query: { enabled }
  });
  const delegate = useReadContract({
    address: addresses.govToken,
    abi: erc20Abi,
    functionName: "delegates",
    args: address ? [address] : undefined,
    query: { enabled }
  });
  const reserves = useReadContract({
    address: addresses.amm,
    abi: ammAbi,
    functionName: "reserves"
  });

  const proposalQuery = useMemo(
    () => gql`
      {
        proposals(first: 5, orderBy: createdAt, orderDirection: desc) {
          id
          proposer
          description
          state
        }
        swaps(first: 5, orderBy: timestamp, orderDirection: desc) {
          id
          trader
          amountIn
          amountOut
        }
      }
    `,
    []
  );

  const indexed = useQuery({
    queryKey: ["subgraph"],
    queryFn: async () =>
      addresses.subgraph
        ? request(addresses.subgraph, proposalQuery)
        : { proposals: [], swaps: [] },
    refetchInterval: 15000
  });

  async function runTx(label: string, fn: () => Promise<unknown>) {
    setUiError("");
    try {
      await fn();
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (message.includes("User rejected"))
        setUiError(`${label}: transaction rejected in wallet.`);
      else if (message.includes("insufficient")) setUiError(`${label}: insufficient balance.`);
      else setUiError(`${label}: ${message.split("\n")[0]}`);
    }
  }

  return (
    <main>
      <header>
        <div>
          <p className="eyebrow">GameFi Economy</p>
          <h1>DAO-governed crafting economy</h1>
        </div>
        <div className="connectors">
          {connectors.map((connector) => (
            <button key={connector.uid} onClick={() => connect({ connector })}>
              {connector.name}
            </button>
          ))}
        </div>
      </header>

      {(wrongNetwork || uiError || connectError || writeError) && (
        <section className="alert">
          {wrongNetwork && <p>Wrong network. Switch MetaMask to Base Sepolia.</p>}
          {uiError && <p>{uiError}</p>}
          {connectError && <p>{connectError.message}</p>}
          {writeError && <p>{writeError.message}</p>}
        </section>
      )}

      <section className="grid">
        <article>
          <span>Wallet</span>
          <strong>
            {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : "Not connected"}
          </strong>
        </article>
        <article>
          <span>Governance balance</span>
          <strong>{formatWei(balance.data)} GFG</strong>
        </article>
        <article>
          <span>Voting power</span>
          <strong>{formatWei(votes.data)} votes</strong>
        </article>
        <article>
          <span>Delegate</span>
          <strong>
            {delegate.data ? `${delegate.data.slice(0, 6)}...${delegate.data.slice(-4)}` : "-"}
          </strong>
        </article>
      </section>

      <section className="panel">
        <h2>Protocol Actions</h2>
        <div className="actions">
          <button
            disabled={!address || isPending}
            onClick={() =>
              runTx("Delegate", () =>
                writeContractAsync({
                  address: addresses.govToken,
                  abi: erc20Abi,
                  functionName: "delegate",
                  args: [address!]
                })
              )
            }
          >
            Delegate to self
          </button>
          <button
            disabled={!address || isPending}
            onClick={() =>
              runTx("Swap", () =>
                writeContractAsync({
                  address: addresses.amm,
                  abi: ammAbi,
                  functionName: "swap",
                  args: [addresses.wood, 10n ** 18n, 1n]
                })
              )
            }
          >
            Swap 1 WOOD
          </button>
          <button
            disabled={!address || isPending}
            onClick={() =>
              runTx("Vote", () =>
                writeContractAsync({
                  address: addresses.governor,
                  abi: governorAbi,
                  functionName: "castVote",
                  args: [1n, 1]
                })
              )
            }
          >
            Vote yes
          </button>
        </div>
      </section>

      <section className="columns">
        <article className="panel">
          <h2>AMM Reserves</h2>
          <p>WOOD: {formatWei(reserves.data?.[0])}</p>
          <p>CRYSTAL: {formatWei(reserves.data?.[1])}</p>
        </article>
        <article className="panel">
          <h2>Subgraph Feed</h2>
          <pre>{JSON.stringify(indexed.data, null, 2)}</pre>
        </article>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(
  <WagmiProvider config={config}>
    <QueryClientProvider client={queryClient}>
      <Dashboard />
    </QueryClientProvider>
  </WagmiProvider>
);
