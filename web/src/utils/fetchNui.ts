export async function fetchNui<T = any>(eventName: string, data?: any): Promise<T> {
  const options = {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  }

  let resourceName = "unknown"

  if (typeof window !== "undefined") {
    if (typeof (window as any).GetParentResourceName === "function") {
      resourceName = (window as any).GetParentResourceName()
    } else {
      console.warn("⚠️ GetParentResourceName not available, using fallback name.")
      resourceName = "muhaddil_insurance"
    }
  }

  const resp = await fetch(`https://${resourceName}/${eventName}`, options)

  try {
    return await resp.json()
  } catch (e) {
    console.error("❌ fetchNui JSON parse error:", e)
    throw e
  }
}
