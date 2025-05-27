;; City Verification Contract
;; Validates floating city infrastructure and registration

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_CITY_EXISTS (err u101))
(define-constant ERR_CITY_NOT_FOUND (err u102))
(define-constant ERR_INVALID_COORDINATES (err u103))

;; City status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)

;; Data structures
(define-map cities
  { city-id: uint }
  {
    name: (string-ascii 50),
    coordinates: { lat: int, lng: int },
    population-capacity: uint,
    infrastructure-score: uint,
    status: uint,
    registered-at: uint,
    verified-at: (optional uint)
  }
)

(define-map city-owners
  { city-id: uint }
  { owner: principal }
)

(define-data-var next-city-id uint u1)

;; Register a new floating city
(define-public (register-city (name (string-ascii 50)) (lat int) (lng int) (capacity uint))
  (let ((city-id (var-get next-city-id)))
    (asserts! (and (>= lat -90000000) (<= lat 90000000)) ERR_INVALID_COORDINATES)
    (asserts! (and (>= lng -180000000) (<= lng 180000000)) ERR_INVALID_COORDINATES)
    (asserts! (> capacity u0) ERR_INVALID_COORDINATES)

    (map-set cities
      { city-id: city-id }
      {
        name: name,
        coordinates: { lat: lat, lng: lng },
        population-capacity: capacity,
        infrastructure-score: u0,
        status: STATUS_PENDING,
        registered-at: block-height,
        verified-at: none
      }
    )

    (map-set city-owners
      { city-id: city-id }
      { owner: tx-sender }
    )

    (var-set next-city-id (+ city-id u1))
    (ok city-id)
  )
)

;; Verify a city (admin only)
(define-public (verify-city (city-id uint) (infrastructure-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= infrastructure-score u100) ERR_INVALID_COORDINATES)

    (match (map-get? cities { city-id: city-id })
      city-data
      (begin
        (map-set cities
          { city-id: city-id }
          (merge city-data {
            infrastructure-score: infrastructure-score,
            status: STATUS_VERIFIED,
            verified-at: (some block-height)
          })
        )
        (ok true)
      )
      ERR_CITY_NOT_FOUND
    )
  )
)

;; Get city information
(define-read-only (get-city (city-id uint))
  (map-get? cities { city-id: city-id })
)

;; Get city owner
(define-read-only (get-city-owner (city-id uint))
  (map-get? city-owners { city-id: city-id })
)

;; Check if city is verified
(define-read-only (is-city-verified (city-id uint))
  (match (map-get? cities { city-id: city-id })
    city-data (is-eq (get status city-data) STATUS_VERIFIED)
    false
  )
)
