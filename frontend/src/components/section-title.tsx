type SectionTitleProps = {
  eyebrow: string
  title: string
  text: string
}

export function SectionTitle({ eyebrow, title, text }: SectionTitleProps) {
  return (
    <div className="section-title">
      <span className="section-title__eyebrow">{eyebrow}</span>
      <h2>{title}</h2>
      <p>{text}</p>
    </div>
  )
}
