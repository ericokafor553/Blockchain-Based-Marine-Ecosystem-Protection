;; Conservation Funding Contract
;; Manages marine protection financing and grants

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INSUFFICIENT_FUNDS (err u501))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u502))
(define-constant ERR_INVALID_AMOUNT (err u503))
(define-constant ERR_PROPOSAL_EXPIRED (err u504))

;; Data structures
(define-map funding-proposals
  { proposal-id: uint }
  {
    title: (string-ascii 200),
    description: (string-ascii 1000),
    area-id: uint,
    requested-amount: uint,
    raised-amount: uint,
    proposer: principal,
    deadline: uint,
    approved: bool,
    completed: bool,
    created-at: uint
  }
)

(define-map donations
  { donation-id: uint }
  {
    proposal-id: uint,
    donor: principal,
    amount: uint,
    timestamp: uint
  }
)

(define-map funding-pool principal uint)
(define-data-var next-proposal-id uint u1)
(define-data-var next-donation-id uint u1)
(define-data-var total-pool uint u0)

;; Read-only functions
(define-read-only (get-funding-proposal (proposal-id uint))
  (map-get? funding-proposals { proposal-id: proposal-id })
)

(define-read-only (get-donation (donation-id uint))
  (map-get? donations { donation-id: donation-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (map-get? funding-pool user))
)

(define-read-only (get-total-pool)
  (var-get total-pool)
)

(define-read-only (get-proposal-progress (proposal-id uint))
  (match (map-get? funding-proposals { proposal-id: proposal-id })
    proposal (/ (* (get raised-amount proposal) u100) (get requested-amount proposal))
    u0
  )
)

;; Public functions
(define-public (deposit-funds (amount uint))
  (let ((current-balance (get-user-balance tx-sender)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)

    (map-set funding-pool tx-sender (+ current-balance amount))
    (var-set total-pool (+ (var-get total-pool) amount))
    (ok true)
  )
)

(define-public (create-funding-proposal
  (title (string-ascii 200))
  (description (string-ascii 1000))
  (area-id uint)
  (requested-amount uint)
  (duration-blocks uint)
)
  (let ((proposal-id (var-get next-proposal-id)))
    (asserts! (> requested-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration-blocks u0) ERR_INVALID_AMOUNT)

    (map-set funding-proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        area-id: area-id,
        requested-amount: requested-amount,
        raised-amount: u0,
        proposer: tx-sender,
        deadline: (+ block-height duration-blocks),
        approved: false,
        completed: false,
        created-at: block-height
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (approve-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? funding-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set funding-proposals
      { proposal-id: proposal-id }
      (merge proposal { approved: true })
    )
    (ok true)
  )
)

(define-public (donate-to-proposal (proposal-id uint) (amount uint))
  (let (
    (proposal (unwrap! (map-get? funding-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    (user-balance (get-user-balance tx-sender))
    (donation-id (var-get next-donation-id))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_FUNDS)
    (asserts! (get approved proposal) ERR_UNAUTHORIZED)
    (asserts! (> (get deadline proposal) block-height) ERR_PROPOSAL_EXPIRED)

    ;; Transfer funds
    (map-set funding-pool tx-sender (- user-balance amount))

    ;; Update proposal
    (map-set funding-proposals
      { proposal-id: proposal-id }
      (merge proposal { raised-amount: (+ (get raised-amount proposal) amount) })
    )

    ;; Record donation
    (map-set donations
      { donation-id: donation-id }
      {
        proposal-id: proposal-id,
        donor: tx-sender,
        amount: amount,
        timestamp: block-height
      }
    )
    (var-set next-donation-id (+ donation-id u1))
    (ok donation-id)
  )
)

(define-public (withdraw-funds (proposal-id uint))
  (let ((proposal (unwrap! (map-get? funding-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get proposer proposal)) ERR_UNAUTHORIZED)
    (asserts! (get approved proposal) ERR_UNAUTHORIZED)
    (asserts! (>= (get raised-amount proposal) (get requested-amount proposal)) ERR_INSUFFICIENT_FUNDS)

    (map-set funding-proposals
      { proposal-id: proposal-id }
      (merge proposal { completed: true })
    )
    (ok (get raised-amount proposal))
  )
)
