"use client"

import { useState, useEffect } from "react"
import { Shield, Users, DollarSign, Clock, X, RefreshCw } from "lucide-react"
import type { NearbyPlayer } from "../types/insurance"
import { fetchNui } from "../utils/fetchNui"
import { ThemeSelector, type Theme } from "./ThemeSelector"

interface Props {
  playerJob: string
  onClose: () => void
  insuranceTypes: Record<string, { label: string; price: number; duration: number }>
  t: (key: string, ...args: any[]) => string
}

export function SellInsurance({ playerJob, onClose, insuranceTypes, t }: Props) {
  const [nearbyPlayers, setNearbyPlayers] = useState<NearbyPlayer[]>([])
  const [selectedPlayer, setSelectedPlayer] = useState<number | null>(null)
  const [insuranceType, setInsuranceType] = useState("basic")
  const [duration, setDuration] = useState(1)
  const [price, setPrice] = useState(5000)
  const [isRefreshing, setIsRefreshing] = useState(false)

  const [theme, setTheme] = useState<Theme>(() => {
    if (typeof window !== "undefined") {
      return (localStorage.getItem("theme") as Theme) || "dark"
    }
    return "dark"
  })

  useEffect(() => {
    if (typeof window !== "undefined" && "localStorage" in window) {
      localStorage.setItem("theme", theme)
      document.documentElement.setAttribute("data-theme", theme)
    }
  }, [theme])

  useEffect(() => {
    loadNearbyPlayers()
  }, [])

  const loadNearbyPlayers = async () => {
    setIsRefreshing(true)
    try {
      const response = await fetchNui<{ players: NearbyPlayer[] }>("getNearbyPlayers")
      setNearbyPlayers(Array.isArray(response.players) ? response.players : [])
    } catch (error) {
      console.error("Error loading nearby players:", error)
      setNearbyPlayers([])
    } finally {
      setTimeout(() => setIsRefreshing(false), 500)
    }
  }

  const handleSellInsurance = () => {
    if (!selectedPlayer) return

    onClose()

    fetchNui("sellCustomInsurance", {
      targetId: selectedPlayer,
      insuranceType,
      duration,
      price,
    })
  }

  useEffect(() => {
    const selectedConfig = insuranceTypes[insuranceType]
    if (selectedConfig) {
      setPrice(selectedConfig.price)
      setDuration(selectedConfig.duration)
    }
  }, [insuranceType, insuranceTypes])

  return (
    <div className={`insurance-container theme-${theme}`}>
      <div className="insurance-modal sell-modal">
        <div className="insurance-header">
          <div className="header-left">
            <Shield size={24} />
            <div>
              <h1>{t("sell_insurance")}</h1>
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

        <div className="sell-content">
          <div className="sell-section">
            <div className="section-header">
              <Users size={18} />
              <h2>{t("nearby_players")}</h2>
              <button onClick={loadNearbyPlayers} className={`refresh-btn ${isRefreshing ? "spinning" : ""}`}>
                <RefreshCw size={16} />
              </button>
            </div>

            {nearbyPlayers.length === 0 ? (
              <div className="empty-state">
                <Users size={40} />
                <p>{t("no_nearby_players")}</p>
                <button onClick={loadNearbyPlayers} className="refresh-btn-large">
                  {t("refresh")}
                </button>
              </div>
            ) : (
              <div className="players-list">
                {nearbyPlayers.map((player) => (
                  <div
                    key={player.id}
                    className={`player-card ${selectedPlayer === player.id ? "selected" : ""}`}
                    onClick={() => setSelectedPlayer(player.id)}
                  >
                    <div className="player-avatar">
                      <Users size={18} />
                    </div>
                    <div className="player-info">
                      <span className="player-name">{player.name}</span>
                      <span className="player-distance">{player.distance}m</span>
                    </div>
                    {selectedPlayer === player.id && <div className="selected-indicator" />}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="sell-section">
            <div className="section-header">
              <Shield size={18} />
              <h2>{t("configure_insurance")}</h2>
            </div>

            <div className="sell-form">
              <div className="form-group">
                <label>
                  <Shield size={14} />
                  {t("type")}
                </label>
                <select value={insuranceType} onChange={(e) => setInsuranceType(e.target.value)}>
                  {Object.entries(insuranceTypes)
                    .sort(([, a], [, b]) => a.duration - b.duration)
                    .map(([key, value]) => (
                      <option key={key} value={key}>
                        {value.label} {t("for")} {value.duration} {value.duration === 1 ? t("day") : t("days")}
                      </option>
                    ))}
                </select>
              </div>

              <div className="form-group">
                <label>
                  <Clock size={14} />
                  {t("duration_days")}
                </label>
                <input
                  type="number"
                  min="1"
                  max="365"
                  value={duration}
                  onChange={(e) => setDuration(Number.parseInt(e.target.value) || 1)}
                />
              </div>

              <div className="form-group">
                <label>
                  <DollarSign size={14} />
                  {t("price")}
                </label>
                <input
                  type="number"
                  min="0"
                  step="100"
                  value={price}
                  onChange={(e) => setPrice(Number.parseInt(e.target.value) || 0)}
                />
              </div>

              <div className="summary">
                <div className="summary-item">
                  <span>{t("plan")}</span>
                  <span>{insuranceTypes[insuranceType]?.label}</span>
                </div>
                <div className="summary-item">
                  <span>{t("duration")}</span>
                  <span>{duration}d</span>
                </div>
                <div className="summary-item highlight">
                  <span>{t("total")}</span>
                  <span>${price.toLocaleString()}</span>
                </div>
              </div>

              <button onClick={handleSellInsurance} disabled={!selectedPlayer} className="sell-btn">
                {t("sell_insurance_button")}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
