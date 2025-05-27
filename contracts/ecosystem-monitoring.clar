;; Ecosystem Monitoring Contract
;; Tracks marine biodiversity and ecosystem health

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_DATA (err u201))
(define-constant ERR_RECORD_NOT_FOUND (err u202))

;; Data structures
(define-map ecosystem-records
  { record-id: uint }
  {
    area-id: uint,
    species-count: uint,
    water-quality: uint, ;; 1-100 scale
    coral-coverage: uint, ;; percentage
    fish-population: uint,
    pollution-level: uint, ;; 1-10 scale (1 = clean, 10 = heavily polluted)
    recorded-at: uint,
    recorder: principal
  }
)

(define-map authorized-monitors principal bool)
(define-data-var next-record-id uint u1)

;; Read-only functions
(define-read-only (get-ecosystem-record (record-id uint))
  (map-get? ecosystem-records { record-id: record-id })
)

(define-read-only (is-authorized-monitor (monitor principal))
  (default-to false (map-get? authorized-monitors monitor))
)

(define-read-only (get-latest-record-for-area (area-id uint))
  ;; This is a simplified version - in practice, you'd want to iterate through records
  (map-get? ecosystem-records { record-id: (- (var-get next-record-id) u1) })
)

;; Public functions
(define-public (authorize-monitor (monitor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-monitors monitor true)
    (ok true)
  )
)

(define-public (record-ecosystem-data
  (area-id uint)
  (species-count uint)
  (water-quality uint)
  (coral-coverage uint)
  (fish-population uint)
  (pollution-level uint)
)
  (let ((record-id (var-get next-record-id)))
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-authorized-monitor tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (and (<= water-quality u100) (> water-quality u0)) ERR_INVALID_DATA)
    (asserts! (<= coral-coverage u100) ERR_INVALID_DATA)
    (asserts! (and (<= pollution-level u10) (> pollution-level u0)) ERR_INVALID_DATA)

    (map-set ecosystem-records
      { record-id: record-id }
      {
        area-id: area-id,
        species-count: species-count,
        water-quality: water-quality,
        coral-coverage: coral-coverage,
        fish-population: fish-population,
        pollution-level: pollution-level,
        recorded-at: block-height,
        recorder: tx-sender
      }
    )
    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

(define-public (revoke-monitor (monitor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete authorized-monitors monitor)
    (ok true)
  )
)
