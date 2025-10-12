"use client"

import { useEffect } from "react"

export const useNuiEvent = <T = any>(action: string, handler: (data: T) => void) => {
  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const { action: eventAction, ...data } = event.data

      if (eventAction === action) {
        handler(data as T)
      }
    }

    window.addEventListener("message", eventListener)

    return () => window.removeEventListener("message", eventListener)
  }, [action, handler])
}
