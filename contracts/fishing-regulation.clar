;; Fishing Regulation Contract
;; Manages sustainable fishing practices and quotas

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_QUOTA_EXCEEDED (err u301))
(define-constant ERR_INVALID_LICENSE (err u302))
(define-constant ERR_AREA_RESTRICTED (err u303))

;; Data structures
(define-map fishing-licenses
  { license-id: uint }
  {
    holder: principal,
    area-id: uint,
    species: (string-ascii 50),
    quota-kg: uint,
    used-quota: uint,
    valid-until: uint,
    active: bool
  }
)

(define-map fishing-records
  { record-id: uint }
  {
    license-id: uint,
    catch-kg: uint,
    species: (string-ascii 50),
    location: (string-ascii 100),
    timestamp: uint,
    fisher: principal
  }
)

(define-map area-restrictions
  { area-id: uint }
  {
    restricted: bool,
    reason: (string-ascii 200),
    restriction-until: uint
  }
)

(define-data-var next-license-id uint u1)
(define-data-var next-record-id uint u1)

;; Read-only functions
(define-read-only (get-fishing-license (license-id uint))
  (map-get? fishing-licenses { license-id: license-id })
)

(define-read-only (get-fishing-record (record-id uint))
  (map-get? fishing-records { record-id: record-id })
)

(define-read-only (is-area-restricted (area-id uint))
  (match (map-get? area-restrictions { area-id: area-id })
    restriction (and (get restricted restriction) (<= block-height (get restriction-until restriction)))
    false
  )
)

(define-read-only (get-remaining-quota (license-id uint))
  (match (map-get? fishing-licenses { license-id: license-id })
    license (- (get quota-kg license) (get used-quota license))
    u0
  )
)

;; Public functions
(define-public (issue-fishing-license
  (holder principal)
  (area-id uint)
  (species (string-ascii 50))
  (quota-kg uint)
  (valid-blocks uint)
)
  (let ((license-id (var-get next-license-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (is-area-restricted area-id)) ERR_AREA_RESTRICTED)

    (map-set fishing-licenses
      { license-id: license-id }
      {
        holder: holder,
        area-id: area-id,
        species: species,
        quota-kg: quota-kg,
        used-quota: u0,
        valid-until: (+ block-height valid-blocks),
        active: true
      }
    )
    (var-set next-license-id (+ license-id u1))
    (ok license-id)
  )
)

(define-public (record-catch
  (license-id uint)
  (catch-kg uint)
  (location (string-ascii 100))
)
  (let (
    (license (unwrap! (map-get? fishing-licenses { license-id: license-id }) ERR_INVALID_LICENSE))
    (record-id (var-get next-record-id))
  )
    (asserts! (is-eq tx-sender (get holder license)) ERR_UNAUTHORIZED)
    (asserts! (get active license) ERR_INVALID_LICENSE)
    (asserts! (<= block-height (get valid-until license)) ERR_INVALID_LICENSE)
    (asserts! (<= (+ (get used-quota license) catch-kg) (get quota-kg license)) ERR_QUOTA_EXCEEDED)
    (asserts! (not (is-area-restricted (get area-id license))) ERR_AREA_RESTRICTED)

    ;; Update license quota
    (map-set fishing-licenses
      { license-id: license-id }
      (merge license { used-quota: (+ (get used-quota license) catch-kg) })
    )

    ;; Record the catch
    (map-set fishing-records
      { record-id: record-id }
      {
        license-id: license-id,
        catch-kg: catch-kg,
        species: (get species license),
        location: location,
        timestamp: block-height,
        fisher: tx-sender
      }
    )
    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

(define-public (restrict-area (area-id uint) (reason (string-ascii 200)) (duration-blocks uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set area-restrictions
      { area-id: area-id }
      {
        restricted: true,
        reason: reason,
        restriction-until: (+ block-height duration-blocks)
      }
    )
    (ok true)
  )
)
