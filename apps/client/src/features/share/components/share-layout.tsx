import { Outlet } from "react-router-dom";
import ShareShell from "@/features/share/components/share-shell.tsx";
import { useRTL } from "@/hooks/use-rtl";

export default function ShareLayout() {
  useRTL(); // Enable RTL support for shared pages
  
  return (
    <ShareShell>
      <Outlet />
    </ShareShell>
  );
}
