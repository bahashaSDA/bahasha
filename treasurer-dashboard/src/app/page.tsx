import { redirect } from "next/navigation";

/** The dashboard is the product; send the root straight to it. */
export default function Home() {
  redirect("/dashboard");
}
