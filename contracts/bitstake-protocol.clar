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