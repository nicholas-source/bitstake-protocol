;; Title: BitStake Protocol - Decentralized sBTC Staking Platform
;; Summary: A Bitcoin Layer 2 staking protocol that enables users to earn
;;          rewards on their sBTC holdings through time-locked staking
;; Description: BitStake Protocol leverages Stacks' Bitcoin finality to 
;;              provide secure, yield-generating opportunities for sBTC 
;;              holders. Users can stake their synthetic Bitcoin (sBTC) 
;;              for flexible periods and earn dynamic rewards based on 
;;              staking duration and pool participation. The protocol 
;;              features configurable reward rates, minimum lock periods,
;;              and transparent reward distribution mechanics.

;; ERROR CONSTANTS

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ZERO_STAKE (err u101))
(define-constant ERR_NO_STAKE_FOUND (err u102))
(define-constant ERR_TOO_EARLY_TO_UNSTAKE (err u103))
(define-constant ERR_INVALID_REWARD_RATE (err u104))
(define-constant ERR_NOT_ENOUGH_REWARDS (err u105))
(define-constant ERR_INVALID_PERIOD (err u106))
(define-constant ERR_OWNER_UNCHANGED (err u107))

;; DATA STORAGE

;; Staking records for each user
(define-map stakes
  { staker: principal }
  {
    amount: uint,
    staked-at: uint,
  }
)

;; Track total rewards claimed by each staker
(define-map rewards-claimed
  { staker: principal }
  { amount: uint }
)

;; PROTOCOL CONFIGURATION

;; Reward rate in basis points (5 = 0.5%)
(define-data-var reward-rate uint u5)

;; Total reward pool available for distribution
(define-data-var reward-pool uint u0)

;; Minimum staking period in blocks (~10 days on Stacks mainnet)
(define-data-var min-stake-period uint u1440)

;; Total amount of sBTC currently staked in the protocol
(define-data-var total-staked uint u0)

;; Contract owner for administrative functions
(define-data-var contract-owner principal tx-sender)

;; ADMINISTRATIVE FUNCTIONS

;; Get the current contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Transfer ownership to a new principal
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq new-owner (var-get contract-owner)))
      ERR_OWNER_UNCHANGED
    )
    (ok (var-set contract-owner new-owner))
  )
)

;; Update the reward rate (owner only)
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (< new-rate u1000) ERR_INVALID_REWARD_RATE) ;; Max 100% (1000 basis points)
    (ok (var-set reward-rate new-rate))
  )
)

;; Update the minimum staking period (owner only)
(define-public (set-min-stake-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-period u0) ERR_INVALID_PERIOD)
    (ok (var-set min-stake-period new-period))
  )
)

;; Add sBTC to the reward pool for distribution
(define-public (add-to-reward-pool (amount uint))
  (begin
    (asserts! (> amount u0) ERR_ZERO_STAKE)
    ;; Transfer sBTC from sender to contract
    (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer amount tx-sender (as-contract tx-sender) none
    ))
    ;; Increase reward pool balance
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)

;; CORE STAKING FUNCTIONS

;; Stake sBTC tokens to earn rewards
(define-public (stake (amount uint))
  (begin
    (asserts! (> amount u0) ERR_ZERO_STAKE)
    ;; Transfer sBTC from user to contract
    (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer amount tx-sender (as-contract tx-sender) none
    ))
    ;; Update or create stake record
    (match (map-get? stakes { staker: tx-sender })
      prev-stake
      ;; Add to existing stake
      (map-set stakes { staker: tx-sender } {
        amount: (+ amount (get amount prev-stake)),
        staked-at: stacks-block-height,
      })
      ;; Create new stake record
      (map-set stakes { staker: tx-sender } {
        amount: amount,
        staked-at: stacks-block-height,
      })
    )
    ;; Update total staked amount
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

;; Calculate pending rewards for a staker
(define-read-only (calculate-rewards (staker principal))
  (match (map-get? stakes { staker: staker })
    stake-info
    (let (
        (stake-amount (get amount stake-info))
        (stake-duration (- stacks-block-height (get staked-at stake-info)))
        (reward-basis (/ (* stake-amount (var-get reward-rate)) u1000))
        (blocks-per-year u52560) ;; Approximately 365 days on Stacks
        (time-factor (/ (* stake-duration u10000) blocks-per-year))
        (reward (* reward-basis (/ time-factor u10000)))
      )
      reward
    )
    u0 ;; No stake found
  )
)

;; Claim accumulated rewards without unstaking
(define-public (claim-rewards)
  (let (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) ERR_NO_STAKE_FOUND))
      (reward-amount (calculate-rewards tx-sender))
    )
    (asserts! (> reward-amount u0) ERR_NO_STAKE_FOUND)
    (asserts! (<= reward-amount (var-get reward-pool)) ERR_NOT_ENOUGH_REWARDS)
    ;; Deduct rewards from pool
    (var-set reward-pool (- (var-get reward-pool) reward-amount))
    ;; Update claimed rewards record
    (match (map-get? rewards-claimed { staker: tx-sender })
      prev-claimed (map-set rewards-claimed { staker: tx-sender } { amount: (+ reward-amount (get amount prev-claimed)) })
      (map-set rewards-claimed { staker: tx-sender } { amount: reward-amount })
    )
    ;; Reset stake timer for reward calculation
    (map-set stakes { staker: tx-sender } {
      amount: (get amount stake-info),
      staked-at: stacks-block-height,
    })
    ;; Transfer rewards to staker
    (as-contract (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer reward-amount (as-contract tx-sender) tx-sender none
    )))
    (ok true)
  )
)