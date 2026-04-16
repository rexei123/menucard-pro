'use client';

import { Icon } from './icon';

type BadgeVariant =
  | 'default'
  | 'primary'
  | 'success'
  | 'warning'
  | 'error'
  | 'info'
  | 'new'
  | 'top'
  | 'bestseller'
  | 'hot'
  | 'vegetarian'
  | 'vegan'
  | 'signature';

type BadgeSize = 'sm' | 'md';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: BadgeSize;
  icon?: string;
  pill?: boolean;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-[var(--color-bg-muted)] text-[var(--color-text-secondary)]',
  primary: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
  success: 'bg-[var(--color-success-light)] text-[var(--color-success)]',
  warning: 'bg-[var(--color-warning-light)] text-[var(--color-warning)]',
  error: 'bg-[var(--color-error-light)] text-[var(--color-error)]',
  info: 'bg-[var(--color-info-light)] text-[var(--color-info)]',
  new: 'bg-[var(--color-badge-new)] text-white',
  top: 'bg-[var(--color-badge-top)] text-white',
  bestseller: 'bg-[var(--color-badge-bestseller)] text-white',
  hot: 'bg-[var(--color-badge-hot)] text-white',
  vegetarian: 'bg-[var(--color-success-light)] text-[var(--color-badge-vegetarian)]',
  vegan: 'bg-emerald-50 text-[var(--color-badge-vegan)]',
  signature: 'bg-purple-50 text-[var(--color-badge-signature)]',
};

const sizeClasses: Record<BadgeSize, string> = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-3 py-1 text-xs',
};

export function Badge({
  children,
  variant = 'default',
  size = 'sm',
  icon,
  pill = false,
  className = '',
}: BadgeProps) {
  return (
    <span
      className={`
        inline-flex items-center gap-1 font-medium
        ${pill ? 'rounded-full' : 'rounded-[var(--radius-sm)]'}
        ${variantClasses[variant]}
        ${sizeClasses[size]}
        ${className}
      `.trim()}
    >
      {icon && <Icon name={icon} size={14} />}
      {children}
    </span>
  );
}
