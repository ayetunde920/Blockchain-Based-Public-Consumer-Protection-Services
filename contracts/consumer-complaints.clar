;; Consumer Complaint Processing Contract
;; Manages complaints against businesses and service providers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-COMPLAINT-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-INVALID-STATUS (err u203))
(define-constant ERR-INVALID-SEVERITY (err u204))

;; Data Variables
(define-data-var contract-owner principal CONTRACT-OWNER)
(define-data-var complaint-counter uint u0)

;; Data Maps
(define-map authorized-processors principal bool)
(define-map complaints
  { complaint-id: uint }
  {
    complainant: principal,
    business-id: (string-ascii 50),
    category: (string-ascii 100),
    description: (string-ascii 500),
    severity: uint,
    status: (string-ascii 20),
    filed-date: uint,
    resolved-date: (optional uint),
    processor: (optional principal)
  }
)

(define-map complaint-updates
  { complaint-id: uint, update-sequence: uint }
  {
    updater: principal,
    timestamp: uint,
    status: (string-ascii 20),
    notes: (string-ascii 300)
  }
)

(define-map business-complaint-stats
  { business-id: (string-ascii 50) }
  {
    total-complaints: uint,
    resolved-complaints: uint,
    average-severity: uint,
    last-complaint-date: uint
  }
)

;; Authorization Functions
(define-public (add-authorized-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-processors processor true))
  )
)

(define-public (remove-authorized-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-processors processor))
  )
)

;; Complaint Filing Functions
(define-public (file-complaint
  (business-id (string-ascii 50))
  (category (string-ascii 100))
  (description (string-ascii 500))
  (severity uint)
)
  (let
    (
      (complaint-id (+ (var-get complaint-counter) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len business-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= severity u1) (<= severity u5)) ERR-INVALID-SEVERITY)

    (map-set complaints
      { complaint-id: complaint-id }
      {
        complainant: tx-sender,
        business-id: business-id,
        category: category,
        description: description,
        severity: severity,
        status: "filed",
        filed-date: current-time,
        resolved-date: none,
        processor: none
      }
    )

    (update-business-stats business-id severity current-time)
    (var-set complaint-counter complaint-id)
    (ok complaint-id)
  )
)

(define-public (assign-complaint
  (complaint-id uint)
  (processor principal)
)
  (let
    (
      (complaint-data (unwrap! (map-get? complaints { complaint-id: complaint-id }) ERR-COMPLAINT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (default-to false (map-get? authorized-processors tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status complaint-data) "filed") ERR-INVALID-STATUS)

    (map-set complaints
      { complaint-id: complaint-id }
      (merge complaint-data {
        status: "assigned",
        processor: (some processor)
      })
    )

    (map-set complaint-updates
      { complaint-id: complaint-id, update-sequence: u0 }
      {
        updater: tx-sender,
        timestamp: current-time,
        status: "assigned",
        notes: "Complaint assigned for processing"
      }
    )

    (ok true)
  )
)

(define-public (update-complaint-status
  (complaint-id uint)
  (new-status (string-ascii 20))
  (notes (string-ascii 300))
)
  (let
    (
      (complaint-data (unwrap! (map-get? complaints { complaint-id: complaint-id }) ERR-COMPLAINT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (resolved-date (if (is-eq new-status "resolved") (some current-time) none))
    )
    (asserts! (default-to false (map-get? authorized-processors tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set complaints
      { complaint-id: complaint-id }
      (merge complaint-data {
        status: new-status,
        resolved-date: resolved-date
      })
    )

    (map-set complaint-updates
      { complaint-id: complaint-id, update-sequence: u1 }
      {
        updater: tx-sender,
        timestamp: current-time,
        status: new-status,
        notes: notes
      }
    )

    (if (is-eq new-status "resolved")
      (update-resolved-stats (get business-id complaint-data))
      (ok true)
    )
  )
)

;; Helper Functions
(define-private (update-business-stats
  (business-id (string-ascii 50))
  (severity uint)
  (complaint-date uint)
)
  (let
    (
      (current-stats (default-to
        { total-complaints: u0, resolved-complaints: u0, average-severity: u0, last-complaint-date: u0 }
        (map-get? business-complaint-stats { business-id: business-id })
      ))
      (new-total (+ (get total-complaints current-stats) u1))
      (new-avg-severity (/ (+ (* (get average-severity current-stats) (get total-complaints current-stats)) severity) new-total))
    )
    (map-set business-complaint-stats
      { business-id: business-id }
      {
        total-complaints: new-total,
        resolved-complaints: (get resolved-complaints current-stats),
        average-severity: new-avg-severity,
        last-complaint-date: complaint-date
      }
    )
  )
)

(define-private (update-resolved-stats (business-id (string-ascii 50)))
  (let
    (
      (current-stats (unwrap-panic (map-get? business-complaint-stats { business-id: business-id })))
    )
    (map-set business-complaint-stats
      { business-id: business-id }
      (merge current-stats {
        resolved-complaints: (+ (get resolved-complaints current-stats) u1)
      })
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-complaint (complaint-id uint))
  (map-get? complaints { complaint-id: complaint-id })
)

(define-read-only (get-business-complaint-stats (business-id (string-ascii 50)))
  (map-get? business-complaint-stats { business-id: business-id })
)

(define-read-only (get-complaint-updates (complaint-id uint))
  (list
    (map-get? complaint-updates { complaint-id: complaint-id, update-sequence: u0 })
    (map-get? complaint-updates { complaint-id: complaint-id, update-sequence: u1 })
  )
)

(define-read-only (get-total-complaints)
  (var-get complaint-counter)
)

(define-read-only (is-authorized-processor (processor principal))
  (default-to false (map-get? authorized-processors processor))
)
