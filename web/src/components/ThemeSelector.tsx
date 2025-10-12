"use client"

import React from "react"
import { Palette } from "lucide-react"

export type Theme = "dark" | "red" | "blue" | "purple" | "green"

interface Props {
  currentTheme: Theme
  onThemeChange: (theme: Theme) => void
  t: (key: string, ...args: any[]) => string
}

export const ThemeSelector: React.FC<Props> = ({ currentTheme, onThemeChange, t }) => {
  const themes: { id: Theme; name: string; color: string }[] = [
    { id: "dark", name: "Oscuro", color: "#6b7280" },
    { id: "red", name: "Rojo", color: "#ef4444" },
    { id: "blue", name: "Azul", color: "#3b82f6" },
    { id: "purple", name: "Morado", color: "#a855f7" },
    { id: "green", name: "Verde", color: "#10b981" },
  ]

  return (
    <div className="theme-selector">
      <div className="theme-selector-header">
        <Palette size={16} />
        <span>{t("theme")}</span>
      </div>
      <div className="theme-options">
        {themes.map((theme) => (
          <button
            key={theme.id}
            onClick={() => onThemeChange(theme.id)}
            className={`theme-option ${currentTheme === theme.id ? "active" : ""}`}
            style={{ "--theme-color": theme.color } as React.CSSProperties}
            title={theme.name}
          >
            <div className="theme-color" style={{ background: theme.color }} />
          </button>
        ))}
      </div>
    </div>
  )
}