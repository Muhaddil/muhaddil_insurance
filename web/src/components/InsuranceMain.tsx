"use client"

import { useState, useEffect } from "react"
import { Shield, Clock, DollarSign, X } from "lucide-react"
import type { InsuranceData, InsurancePlan } from "../types/insurance"
import { fetchNui } from "../utils/fetchNui"
import { ThemeSelector, type Theme } from "./ThemeSelector"

interface Props {
  insuranceData: InsuranceData | null
  canSellDiscount: boolean
  playerJob: string
  insuranceTypes: Record<string, { label: string; price: number; duration: number }>
  discountPercentage: string
  onClose: () => void
  t: (key: string, ...args: any[]) => string
}

export function InsuranceMain({ insuranceData, canSellDiscount, playerJob, insuranceTypes, discountPercentage, onClose, t }: Props) {
  const [plans, setPlans] = useState<InsurancePlan[]>([])
  const [selectedPlan, setSelectedPlan] = useState<InsurancePlan | null>(null)
  const [remainingTime, setRemainingTime] = useState<number | null>(insuranceData?.timeRemaining ?? null)

  const [theme, setTheme] = useState<Theme>(() => {
    if (typeof window !== "undefined") {
      return (localStorage.getItem("theme") as Theme) || "dark"
    }
    return "dark"
  })

  useEffect(() => {
    localStorage.setItem("theme", theme)
    document.documentElement.setAttribute("data-theme", theme)
  }, [theme])

  useEffect(() => {
    if (!insuranceTypes) return

    const loadedPlans: InsurancePlan[] = Object.entries(insuranceTypes).map(([key, cfg]) => ({
      type: key,
      name: cfg.label,
      price: cfg.price,
      duration: cfg.duration,
      description: `${cfg.label} ${t("for")} ${cfg.duration} ${cfg.duration === 1 ? t("day") : t("days")}`,
      features: [t("coverage_included")],
    }))

    loadedPlans.sort((a, b) => a.duration - b.duration)

    setPlans(loadedPlans)
  }, [insuranceTypes, t])

  useEffect(() => {
    if (!insuranceData?.timeRemaining) return

    setRemainingTime(insuranceData.timeRemaining)

    const interval = setInterval(() => {
      setRemainingTime((prev) => {
        if (prev === null) return null
        if (prev <= 0) {
          clearInterval(interval)
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => clearInterval(interval)
  }, [insuranceData])

  const handleBuyInsurance = (plan: InsurancePlan) => {
    const discount = parseFloat(discountPercentage) || 0

    const finalPrice = canSellDiscount
      ? Math.floor(plan.price * (1 - discount / 100))
      : plan.price
    onClose()
    fetchNui("buyInsurance", {
      type: plan.type,
      duration: plan.duration,
      price: finalPrice,
    })
  }

  const formatTime = (seconds: number) => {
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = Math.floor(seconds % 60)

    if (days > 0) return `${days}d ${hours}h ${minutes}m ${secs}s`
    if (hours > 0) return `${hours}h ${minutes}m ${secs}s`
    if (minutes > 0) return `${minutes}m ${secs}s`
    return `${secs}s`
  }

  return (
    <div className={`insurance-container theme-${theme}`}>
      <div className="insurance-modal">
        <div className="insurance-header">
          <div className="header-left">
            <Shield size={24} />
            <div>
              <h1>{t("insurance_system")}</h1>
              {playerJob && <span className="job-badge">{playerJob}</span>}
            </div>
          </div>
          <div className="header-right">
            <ThemeSelector currentTheme={theme} onThemeChange={setTheme} t={t} />
            <button onClick={onClose} className="close-btn">
              <X size={20} />
            </button>
          </div>
        </div>

        {insuranceData && (
          <div className="active-insurance">
            <div className="active-header">
              <div className="active-indicator" />
              <span>{t("active_insurance")}</span>
            </div>
            <div className="active-details">
              <div className="detail-item">
                <span className="label">{t("type")}</span>
                <span className="value">{insuranceData.type}</span>
              </div>
              <div className="detail-item">
                <span className="label">{t("time")}</span>
                <span className="value">{remainingTime !== null ? formatTime(remainingTime) : "--"}</span>
              </div>
            </div>
          </div>
        )}

        {!insuranceData ? (
          <div className="plans-section">
            <h2>{t("available_plans")}</h2>
            <div className="plans-grid">
              {plans.map((plan) => {
                const discount = parseFloat(discountPercentage) || 0
                const finalPrice = canSellDiscount
                  ? Math.floor(plan.price * (1 - discount / 100))
                  : plan.price
                const hasDiscount = canSellDiscount && discount > 0

                return (
                  <div
                    key={plan.type}
                    className={`plan-card ${selectedPlan?.type === plan.type ? "selected" : ""}`}
                    onClick={() => setSelectedPlan(plan)}
                  >
                    <div className="plan-icon">
                      <Shield size={20} />
                    </div>
                    <h3>{plan.name}</h3>
                    <div className="plan-price">
                      {hasDiscount ? (
                        <>
                          <span className="discount-badge">-{discountPercentage}%</span>
                          <span className="price original-price">${plan.price.toLocaleString()}</span>
                          <span className="price final-price">${finalPrice.toLocaleString()}</span>
                        </>
                      ) : (
                        <span className="price">${finalPrice.toLocaleString()}</span>
                      )}
                    </div>
                    <p className="plan-desc">{plan.description}</p>
                    <div className="plan-meta">
                      <div className="meta-item">
                        <Clock size={14} />
                        <span>{plan.duration}d</span>
                      </div>
                      <div className="meta-item">
                        <DollarSign size={14} />
                        <span>${Math.floor(finalPrice / plan.duration).toLocaleString()}/d</span>
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        handleBuyInsurance(plan)
                      }}
                      className="buy-btn"
                    >
                      {t("buy")}
                    </button>
                  </div>
                )
              })}
            </div>
          </div>
        ) : (
          <div className="active-message">
            <Shield size={48} />
            <h3>{t("you_are_protected")}</h3>
            <p>
              {t("active_insurance_label")} <strong>{insuranceData.type}</strong>
            </p>
            <p className="time-remaining">
              {t("time_label")} <strong>{remainingTime !== null ? formatTime(remainingTime) : "--"}</strong>
            </p>
          </div>
        )}

        {canSellDiscount && <div className="discount-banner">{t("discount_applied", discountPercentage)}</div>}
      </div>
    </div>
  )
}
