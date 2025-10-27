import bytes from "bytes";
import { castToBoolean } from "@/lib/utils.tsx";

declare global {
  interface Window {
    CONFIG?: Record<string, string>;
  }
}

export function getAppName(): string {
  return "Docmost";
}

export function getAppUrl(): string {
  return `${window.location.protocol}//${window.location.host}`;
}

export function getServerAppUrl(): string {
  return getConfigValue("APP_URL");
}

export function getBackendUrl(): string {
  return getAppUrl() + "/api";
}

export function getCollaborationUrl(): string {
  const baseUrl =
    getConfigValue("COLLAB_URL") ||
    (import.meta.env.DEV ? process.env.APP_URL : getAppUrl());

  const collabUrl = new URL("/collab", baseUrl);
  collabUrl.protocol = collabUrl.protocol === "https:" ? "wss:" : "ws:";
  return collabUrl.toString();
}

export function getSubdomainHost(): string {
  return getConfigValue("SUBDOMAIN_HOST");
}

export function isCloud(): boolean {
  return castToBoolean(getConfigValue("CLOUD"));
}

export function getAvatarUrl(avatarUrl: string) {
  if (!avatarUrl) return null;
  if (avatarUrl?.startsWith("http")) return avatarUrl;

  return getBackendUrl() + "/attachments/img/avatar/" + avatarUrl;
}

export function getSpaceUrl(spaceSlug: string) {
  return "/s/" + spaceSlug;
}

export function getFileUrl(src: string) {
  if (!src) return src;
  if (src.startsWith("http")) return src;
  if (src.startsWith("/api/")) {
    // Remove the '/api' prefix
    return getBackendUrl() + src.substring(4);
  }
  if (src.startsWith("/files/")) {
    return getBackendUrl() + src;
  }
  return src;
}

export function getFileUploadSizeLimit() {
  const limit = getConfigValue("FILE_UPLOAD_SIZE_LIMIT", "50mb");
  return bytes(limit);
}

export function getFileImportSizeLimit() {
  const limit = getConfigValue("FILE_IMPORT_SIZE_LIMIT", "200mb");
  return bytes(limit);
}

export function getDrawioUrl() {
  return getConfigValue("DRAWIO_URL", "https://embed.diagrams.net");
}

export function getBillingTrialDays() {
  return getConfigValue("BILLING_TRIAL_DAYS");
}

export function getPostHogHost() {
  return getConfigValue("POSTHOG_HOST");
}

export function isPostHogEnabled(): boolean {
  return Boolean(getPostHogHost() && getPostHogKey());
}

export function getPostHogKey() {
  return getConfigValue("POSTHOG_KEY");
}

export function getClarityProjectId() {
  return getConfigValue("CLARITY_PROJECT_ID");
}

export function isClarityEnabled(): boolean {
  return Boolean(getClarityProjectId());
}

function getConfigValue(key: string, defaultValue: string = undefined): string {
  // Check if window.CONFIG exists (production mode with backend)
  // If it exists, use it. Otherwise, fallback to process.env (dev mode)
  const hasWindowConfig = typeof window !== 'undefined' && (window as any).CONFIG;

  const rawValue = hasWindowConfig
    ? (window as any).CONFIG[key]
    : process?.env?.[key];

  return rawValue ?? defaultValue;
}
