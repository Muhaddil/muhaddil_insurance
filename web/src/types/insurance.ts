export interface InsuranceData {
  type: string
  duration: number
  timeRemaining: number
}

export interface InsurancePlan {
  type: string
  name: string
  duration: number
  price: number
  description: string
  features: string[]
}

export interface NearbyPlayer {
  id: number
  name: string
  distance: number
}
