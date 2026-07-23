import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

const GlobeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" width="32" height="32">
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
  </svg>
);

const CapIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" width="32" height="32">
    <path strokeLinecap="round" strokeLinejoin="round" d="M4.26 10.147a60.436 60.436 0 00-.491 6.347A48.627 48.627 0 0112 20.904a48.627 48.627 0 018.232-4.41 60.46 60.46 0 00-.491-6.347m-15.482 0a50.57 50.57 0 00-2.658-.813A59.905 59.905 0 0112 3.493a59.902 59.902 0 0110.399 5.84c-.896.248-1.783.52-2.658.814m-15.482 0A50.697 50.697 0 0112 13.489a50.702 50.702 0 017.74-3.342M6.75 15a.75.75 0 100-1.5.75.75 0 000 1.5zm0 0v-3.675A55.378 55.378 0 0112 8.443m-7.007 11.55A5.981 5.981 0 006.75 15.75v-1.5" />
  </svg>
);

const RocketIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" width="32" height="32">
    <path strokeLinecap="round" strokeLinejoin="round" d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 006.16-12.12A14.98 14.98 0 009.631 8.41m5.96 5.96a14.926 14.926 0 01-5.841 2.58m-.119-8.54a6 6 0 00-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 00-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 01-2.448-2.448 14.9 14.9 0 01.06-.312m-2.24 2.39a4.493 4.493 0 00-1.757 4.306 4.438 4.438 0 002.946 2.946 4.493 4.493 0 004.306-1.758q.18-.218.332-.452l-.452-.332z" />
  </svg>
);

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        
        {/* Top Row: Two Column Features */}
        <div className="row">
          <div className={clsx('col col--6')}>
            <div className={styles.featureCard}>
              <div className={styles.iconWrapper}>
                <GlobeIcon />
              </div>
              <Heading as="h3" className={styles.featureTitle}>100% Bahasa Indonesia</Heading>
              <p className={styles.featureDescription}>
                Berhenti bingung dengan istilah bahasa Inggris. Rakoda menggunakan sintaks
                berbahasa Indonesia murni agar Anda bisa langsung mengerti apa yang ditulis 
                oleh kode Anda.
              </p>
            </div>
          </div>
          <div className={clsx('col col--6')}>
            <div className={styles.featureCard}>
              <div className={styles.iconWrapper}>
                <CapIcon />
              </div>
              <Heading as="h3" className={styles.featureTitle}>Sangat Ramah Pemula</Heading>
              <p className={styles.featureDescription}>
                Rakoda didesain tanpa kerumitan instalasi yang membingungkan. Tulis kodenya, 
                jalankan, dan lihat hasilnya. Belajar algoritma menjadi jauh lebih masuk akal.
              </p>
            </div>
          </div>
        </div>

        {/* Bottom Row: Full Width Feature with Image */}
        <div className="row">
          <div className="col col--12">
            <div className={styles.largeFeatureCard}>
              <div className={styles.largeFeatureContent}>
                <div className={styles.iconWrapper}>
                  <RocketIcon />
                </div>
                <Heading as="h3" className={styles.featureTitle}>Alat Lengkap & Modern</Heading>
                <p className={styles.featureDescription}>
                  Dilengkapi dengan <b>RPL Studio</b> (IDE resmi) yang berjalan di semua platform (Android, iOS, Windows, Linux, MacOS), Kamu mendapatkan fitur 
                  Autocompletion, HTTP Workspace, hingga integrasi database secara instan! 
                  Rakoda bukan sekadar bahasa, melainkan ekosistem lengkap untuk memulai karir untuk kamu pelajar di Indonesia.
                </p>
              </div>
              <div className={styles.largeFeatureImage}>
                {/* 
                  TODO: Replace this .png with a .gif if you prefer a moving mockup. 
                  Currently using a high-quality screenshot from your studio. 
                */}
                <img src={useBaseUrl('/img/rpl-studio-demo.png')} alt="RPL Studio Demo" />
              </div>
            </div>
          </div>
        </div>

      </div>
    </section>
  );
}
