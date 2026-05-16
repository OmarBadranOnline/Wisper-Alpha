import React from "react";
import ReactDOM from "react-dom/client";
import App from "./app/App";
import "./index.css";

const rootEl = document.getElementById("root")!;

ReactDOM.createRoot(rootEl).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

window.setTimeout(() => {
  const bootLoader = document.getElementById("boot-loader");
  if (bootLoader) bootLoader.remove();
}, 250);
