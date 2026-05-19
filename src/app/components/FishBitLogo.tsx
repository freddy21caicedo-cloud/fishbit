/**
 * FishBitLogo — Usa los PNGs corporativos reales de FishBit.
 *
 * Archivos requeridos en /public/images/:
 *   • fishbit-icon.png  → solo el ícono del pez geométrico
 *   • fishbit-logo.png  → wordmark completo (opcional)
 *
 * Uso:
 *   <FishBitIcon size={32} />
 *   <FishBitWordmark size={28} showTagline />
 */

/* eslint-disable @next/next/no-img-element */

interface FishBitIconProps {
  /** Tamaño en px (el ícono es cuadrado) */
  size?: number;
  className?: string;
  style?: React.CSSProperties;
}

/** Solo el ícono del pez */
export function FishBitIcon({ size = 32, className, style }: FishBitIconProps) {
  return (
    <img
      src="/images/fishbit-icon.png"
      alt="FishBit"
      width={size}
      height={size}
      className={className}
      style={{
        objectFit: 'contain',
        display: 'block',
        ...style,
      }}
    />
  );
}

interface FishBitWordmarkProps {
  /** Tamaño base de fuente para el texto (px) */
  size?: number;
  /** Muestra el subtítulo "Inteligencia en Crecimiento Acuícola" */
  showTagline?: boolean;
  /** Color del texto principal */
  textColor?: string;
  /** Tamaño del ícono (px). Por defecto ≈ 1.7× el tamaño de fuente */
  iconSize?: number;
}

/** Ícono + wordmark "FishBit" (con "Bit" en cyan) */
export function FishBitWordmark({
  size = 22,
  showTagline = false,
  textColor = 'currentColor',
  iconSize,
}: FishBitWordmarkProps) {
  const resolvedIconSize = iconSize ?? Math.round(size * 1.7);

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem' }}>
      <FishBitIcon size={resolvedIconSize} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
        <span
          style={{
            fontFamily: 'var(--font-heading)',
            fontWeight: 900,
            fontSize: `${size}px`,
            lineHeight: 1.1,
            letterSpacing: '-0.03em',
            color: textColor,
          }}
        >
          Fish<span style={{ color: '#1ECAD4' }}>Bit</span>
        </span>
        {showTagline && (
          <span
            style={{
              fontSize: `${Math.round(size * 0.44)}px`,
              fontWeight: 700,
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
              color: '#1ECAD4',
              marginTop: '1px',
            }}
          >
            Inteligencia Acuícola
          </span>
        )}
      </div>
    </div>
  );
}
