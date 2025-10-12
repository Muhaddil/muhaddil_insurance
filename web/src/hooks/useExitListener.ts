"use client"

import { useEffect } from "react"
import { fetchNui } from "../utils/fetchNui"

export const useExitListener = (onExit?: () => void) => {
  useEffect(() => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        fetchNui("closeNUI")
        if (onExit) onExit()
      }
    }

    window.addEventListener("keydown", handleEscape)

    return () => window.removeEventListener("keydown", handleEscape)
  }, [onExit])
}
