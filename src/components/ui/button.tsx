'use client';

import { forwardRef } from 'react';
import { Icon } from './icon';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  icon?: string;
  iconPosition?: 'left' | 'right';
  iconFill?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
}

const variantClasses: Record<string, string> = {
  primary: 'bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-hover)] active:bg-[var(--color-primary-hover)] shadow-sm',
  secondary: 'bg-transparent border border-[var(--color-border)] text-[var(--color-text)] hover:bg-[var(--color-bg-muted)] active:bg-[var(--color-bg-muted)]',
  ghost: 'bg-transparent text-[var(--color-primary)] hover:bg-[var(--color-primary-subtle)] active:bg-[var(--color-primary-subtle)]',
  danger: 'bg-[var(--color-error)] text-white hover:bg-[#C94444] active:bg-[#C94444] shadow-sm',
  outline: 'bg-transparent border border-[var(--color-primary)] text-[var(--color-primary)] hover:bg-[var(--color-primary-subtle)]',
};

const sizeClasses: Record<string, string> = {
  sm: 'px-3 py-1.5 text-sm gap-1.5',
  md: 'px-4 py-2 text-base gap-2',
  lg: 'px-6 py-3 text-lg gap-2.5',
};

const iconSizes: Record<string, number> = {
  sm: 18,
  md: 20,
  lg: 22,
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      icon,
      iconPosition = 'left',
      iconFill = false,
      loading = false,
      fullWidth = false,
      className = '',
      children,
      disabled,
      ...props
    },
    ref
  ) => {
    const isDisabled = disabled || loading;

    return (
      <button
        ref={ref}
        className={`
          inline-flex items-center justify-center font-medium
          rounded-[var(--radius-md)] transition-all duration-fast
          focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2
          disabled:opacity-50 disabled:pointer-events-none
          ${variantClasses[variant]}
          ${sizeClasses[size]}
          ${fullWidth ? 'w-full' : ''}
          ${className}
        `.trim()}
        disabled={isDisabled}
        {...props}
      >
        {loading && (
          <span className="animate-spin">
            <Icon name="progress_activity" size={iconSizes[size]} />
          </span>
        )}
        {!loading && icon && iconPosition === 'left' && (
          <Icon name={icon} size={iconSizes[size]} fill={iconFill} />
        )}
        {children}
        {!loading && icon && iconPosition === 'right' && (
          <Icon name={icon} size={iconSizes[size]} fill={iconFill} />
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';
