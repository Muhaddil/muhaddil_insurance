"use client"

import { useState, useEffect } from "react"
import { X, Shield, AlertTriangle, CheckCircle, Clock } from "lucide-react"
import { ThemeSelector, type Theme } from "./ThemeSelector"

interface DocumentData {
    playerName: string
    type: string
    duration: number
    price: number
    expiration: number
    expirationDate: string
    issuedAt: string
}

interface Props {
    data: DocumentData | null
    onClose: () => void
    t: (key: string, ...args: any[]) => string
}

function getExpiryStatus(expiration: number) {
    const now = Math.floor(Date.now() / 1000)
    const secondsLeft = expiration - now
    if (secondsLeft <= 0) return { status: "expired" as const, daysLeft: 0, hoursLeft: 0 }
    const daysLeft = Math.floor(secondsLeft / 86400)
    const hoursLeft = Math.floor((secondsLeft % 86400) / 3600)
    if (daysLeft <= 1) return { status: "critical" as const, daysLeft, hoursLeft }
    if (daysLeft <= 7) return { status: "warning" as const, daysLeft, hoursLeft }
    return { status: "valid" as const, daysLeft, hoursLeft }
}

export function InsuranceDocument({ data, onClose, t }: Props) {
    const [theme, setTheme] = useState<Theme>(() => {
        if (typeof window !== "undefined") return (localStorage.getItem("theme") as Theme) || "dark"
        return "dark"
    })

    useEffect(() => {
        if (typeof window !== "undefined") {
            localStorage.setItem("theme", theme)
            document.documentElement.setAttribute("data-theme", theme)
        }
    }, [theme])

    if (!data) return null

    const { status, daysLeft, hoursLeft } = getExpiryStatus(data.expiration)
    const docNumber = `MED-${data.expiration.toString().slice(-6)}-${data.type.slice(0, 3).toUpperCase()}`

    const timeLabel = (() => {
        const rem = t("document_remaining") || "remaining"
        if (status === "expired") return t("document_no_longer_valid") || "No longer valid"
        if (status === "critical") return hoursLeft > 0 ? `${hoursLeft}h ${rem}` : (t("document_expires_soon") || "< 1h remaining")
        return `${daysLeft}d ${hoursLeft}h ${rem}`
    })()

    const statusMap = {
        valid: { icon: <CheckCircle size={13} />, label: t("document_status_valid") || "ACTIVE", pill: "doc-pill-valid", card: "doc-card-valid" },
        warning: { icon: <Clock size={13} />, label: t("document_status_warning") || "EXPIRING SOON", pill: "doc-pill-warning", card: "doc-card-warning" },
        critical: { icon: <AlertTriangle size={13} />, label: t("document_status_critical") || "EXPIRES TODAY", pill: "doc-pill-critical", card: "doc-card-critical" },
        expired: { icon: <AlertTriangle size={13} />, label: t("document_status_expired") || "EXPIRED", pill: "doc-pill-expired", card: "doc-card-expired" },
    }
    const cfg = statusMap[status]

    return (
        <div className={`insurance-container theme-${theme}`}>
            <div className="insurance-modal document-modal">

                <div className="insurance-header">
                    <div className="header-left">
                        <Shield size={20} />
                        <div>
                            <h1 className="doc-header-title">{t("document_title")}</h1>
                            <span className="doc-header-num">{docNumber}</span>
                        </div>
                    </div>
                    <div className="header-right">
                        <ThemeSelector currentTheme={theme} onThemeChange={setTheme} t={t} />
                        <button onClick={onClose} className="close-btn"><X size={18} /></button>
                    </div>
                </div>

                <div className="doc-accent-bar">
                    <div className="doc-seg doc-seg-1" />
                    <div className="doc-seg doc-seg-2" />
                    <div className="doc-seg doc-seg-3" />
                </div>

                <div className="doc-body">

                    <div className="doc-hero">
                        <div className="doc-emblem">
                            <div className="doc-ring doc-ring-outer" />
                            <div className="doc-ring doc-ring-inner" />
                            <Shield size={30} className="doc-shield-icon" />
                        </div>
                        <div className="doc-hero-info">
                            <p className="doc-org-label">{t("document_subtitle")}</p>
                            <h2 className="doc-name">{data.playerName}</h2>
                            <div className="doc-badges">
                                <span className="doc-type-badge">
                                    <span className="doc-type-dot" />
                                    {data.type.toUpperCase()}
                                </span>
                                <span className={`doc-status-badge ${cfg.pill}`}>
                                    {cfg.icon}
                                    {cfg.label}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div className="doc-divider">
                        <div className="doc-divider-line" />
                        <span className="doc-divider-text">{t("document_certified") || "CERTIFIED"}</span>
                        <div className="doc-divider-line" />
                    </div>

                    <div className={`doc-expiry-card ${cfg.card}`}>
                        <div className="doc-expiry-left">
                            <span className="doc-expiry-label">{t("document_valid_until")}</span>
                            <span className="doc-expiry-date">{data.expirationDate}</span>
                        </div>
                        <div className="doc-expiry-right">
                            <div className={`doc-expiry-status-icon ${cfg.pill}`}>{cfg.icon}</div>
                            <span className="doc-expiry-countdown">{timeLabel}</span>
                        </div>
                    </div>

                    <div className="doc-grid">
                        <div className="doc-cell">
                            <span className="doc-cell-label">{t("duration")}</span>
                            <span className="doc-cell-value">
                                {data.duration}<span className="doc-cell-unit"> {data.duration === 1 ? t("day") : t("days")}</span>
                            </span>
                        </div>
                        <div className="doc-cell">
                            <span className="doc-cell-label">{t("price")}</span>
                            <span className="doc-cell-value">${data.price.toLocaleString()}</span>
                        </div>
                        <div className="doc-cell doc-cell-full">
                            <span className="doc-cell-label">{t("document_issued_at")}</span>
                            <span className="doc-cell-value doc-cell-mono">{data.issuedAt}</span>
                        </div>
                    </div>

                    <div className="doc-footer">
                        <Shield size={11} />
                        <span>{t("document_footer")}</span>
                    </div>
                </div>
            </div>
        </div>
    )
}