"use client"

import { useState } from "react"
import { useNuiEvent } from "./useNuiEvent"

export type LocaleData = Record<string, string>

export const useLocale = () => {
  const [locale, setLocale] = useState<LocaleData>({})

  useNuiEvent<{ localeData: LocaleData }>("setLocale", (data) => {
    if (data.localeData) {
      setLocale(data.localeData)
    }
  })

  const t = (key: string, ...args: any[]): string => {
    let text = locale[key] || key

    if (args.length > 0) {
      args.forEach((arg) => {
        text = text.replace("%s", arg)
      })
    }

    return text
  }

  return { t, locale }
}