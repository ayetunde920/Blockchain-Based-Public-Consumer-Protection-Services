;; Business License Verification Contract
;; Manages business licenses and permits for consumer protection

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LICENSE-NOT-FOUND (err u101))
(define-constant ERR-LICENSE-EXPIRED (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-LICENSE-ALREADY-EXISTS (err u104))

;; Data Variables
(define-data-var contract-owner principal CONTRACT-OWNER)
(define-data-var total-licenses uint u0)

;; Data Maps
(define-map authorized-issuers principal bool)
(define-map business-licenses
  { business-id: (string-ascii 50) }
  {
    owner: principal,
    license-type: (string-ascii 100),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    issuer: principal
  }
)

(define-map license-history
  { business-id: (string-ascii 50), sequence: uint }
  {
    action: (string-ascii 50),
    timestamp: uint,
    issuer: principal,
    details: (string-ascii 200)
  }
)

;; Authorization Functions
(define-public (add-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-issuers issuer true))
  )
)

(define-public (remove-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-issuers issuer))
  )
)

;; License Management Functions
(define-public (issue-license
  (business-id (string-ascii 50))
  (owner principal)
  (license-type (string-ascii 100))
  (validity-period uint)
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (expiry-time (+ current-time validity-period))
    )
    (asserts! (default-to false (map-get? authorized-issuers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len business-id) u0) ERR-INVALID-INPUT)
    (asserts! (> validity-period u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? business-licenses { business-id: business-id })) ERR-LICENSE-ALREADY-EXISTS)

    (map-set business-licenses
      { business-id: business-id }
      {
        owner: owner,
        license-type: license-type,
        issue-date: current-time,
        expiry-date: expiry-time,
        status: "active",
        issuer: tx-sender
      }
    )

    (map-set license-history
      { business-id: business-id, sequence: u0 }
      {
        action: "issued",
        timestamp: current-time,
        issuer: tx-sender,
        details: license-type
      }
    )

    (var-set total-licenses (+ (var-get total-licenses) u1))
    (ok business-id)
  )
)

(define-public (renew-license
  (business-id (string-ascii 50))
  (validity-period uint)
)
  (let
    (
      (license-data (unwrap! (map-get? business-licenses { business-id: business-id }) ERR-LICENSE-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (new-expiry (+ current-time validity-period))
    )
    (asserts! (default-to false (map-get? authorized-issuers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> validity-period u0) ERR-INVALID-INPUT)

    (map-set business-licenses
      { business-id: business-id }
      (merge license-data {
        expiry-date: new-expiry,
        status: "active"
      })
    )

    (ok true)
  )
)

(define-public (revoke-license
  (business-id (string-ascii 50))
  (reason (string-ascii 200))
)
  (let
    (
      (license-data (unwrap! (map-get? business-licenses { business-id: business-id }) ERR-LICENSE-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (default-to false (map-get? authorized-issuers tx-sender)) ERR-NOT-AUTHORIZED)

    (map-set business-licenses
      { business-id: business-id }
      (merge license-data { status: "revoked" })
    )

    (map-set license-history
      { business-id: business-id, sequence: u1 }
      {
        action: "revoked",
        timestamp: current-time,
        issuer: tx-sender,
        details: reason
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-license-status (business-id (string-ascii 50)))
  (match (map-get? business-licenses { business-id: business-id })
    license-data
    (let
      (
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (is-expired (> current-time (get expiry-date license-data)))
      )
      (ok {
        status: (if is-expired "expired" (get status license-data)),
        license-type: (get license-type license-data),
        expiry-date: (get expiry-date license-data),
        owner: (get owner license-data)
      })
    )
    ERR-LICENSE-NOT-FOUND
  )
)

(define-read-only (is-license-valid (business-id (string-ascii 50)))
  (match (map-get? business-licenses { business-id: business-id })
    license-data
    (let
      (
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (is-active (is-eq (get status license-data) "active"))
        (not-expired (<= current-time (get expiry-date license-data)))
      )
      (and is-active not-expired)
    )
    false
  )
)

(define-read-only (get-total-licenses)
  (var-get total-licenses)
)

(define-read-only (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer))
)
