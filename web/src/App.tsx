"use client"

import { useState, useCallback } from "react"
import { InsuranceMain } from "./components/InsuranceMain"
import { SellInsurance } from "./components/SellInsurance"
import { InsuranceDocument } from "./components/InsuranceDocument"
import { useNuiEvent } from "./hooks/useNuiEvent"
import { useExitListener } from "./hooks/useExitListener"
import { useLocale } from "./hooks/useLocale"
import { fetchNui } from "./utils/fetchNui"
import { debugData } from "./utils/debugData"
import type { InsuranceData } from "./types/insurance"

debugData([
  {
    action: "openInsurance",
    data: {
      insuranceData: null,
      canSellDiscount: true,
      playerJob: "ambulance",
    },
  },
])

function App() {
  const [isVisible, setIsVisible] = useState(false)
  const [isClosing, setIsClosing] = useState(false)
  const [view, setView] = useState<"main" | "sell" | "document">("main")
  const [insuranceData, setInsuranceData] = useState<InsuranceData | null>(null)
  const [canSellDiscount, setCanSellDiscount] = useState(false)
  const [playerJob, setPlayerJob] = useState("")
  const [insuranceTypes, setInsuranceTypes] = useState<Record<string, { label: string, price: number, duration: number }>>({})
  const [discountPercentage, setDiscountPercentage] = useState("")
  const { t } = useLocale()
  const [documentData, setDocumentData] = useState<any>(null)

  const handleClose = useCallback(() => {
    setIsClosing(true)
    setTimeout(() => {
      setIsVisible(false)
      setIsClosing(false)
      fetchNui("closeNUI")
    }, 300)
  }, [])

  useExitListener(handleClose)

  useNuiEvent("openInsurance", (event: any) => {
    setIsVisible(true)
    setIsClosing(false)
    setView("main")
    setInsuranceData(event.data.insurance)
    setCanSellDiscount(event.data.canSellDiscount || false)
    setPlayerJob(event.data.playerJob || "")
    const config = event.data?.config || {}
    setInsuranceTypes(config.insuranceTypes || {})
    setDiscountPercentage(config.discountPercentage || "")
  })

  useNuiEvent("openSellInsurance", (event: any) => {
    setIsVisible(true)
    setIsClosing(false)
    setView("sell")
    setPlayerJob(event.data?.playerJob || "")
    const config = event.data?.config || {}
    setInsuranceTypes(config.insuranceTypes || {})
  })

  useNuiEvent("openDocument", (event: any) => {
    setIsVisible(true)
    setIsClosing(false)
    setView("document")
    setDocumentData(event.data)
  })

  if (!isVisible) return null

  return (
    <div className={`insurance-container ${isClosing ? 'closing' : ''}`}>
      {view === "document" ? (
        <InsuranceDocument
          data={documentData}
          onClose={handleClose}
          t={t}
        />
      ) : view === "main" ? (
        <InsuranceMain
          insuranceData={insuranceData}
          canSellDiscount={canSellDiscount}
          playerJob={playerJob}
          onClose={handleClose}
          insuranceTypes={insuranceTypes}
          discountPercentage={discountPercentage}
          t={t}
        />
      ) : (
        <SellInsurance
          playerJob={playerJob}
          onClose={handleClose}
          insuranceTypes={insuranceTypes}
          t={t}
        />
      )}
    </div>
  )
}

export default App